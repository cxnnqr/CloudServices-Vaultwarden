# Define OpenStack project config etc.
locals {
  cacert_file = "./os-trusted-cas"
  router_name = "CloudServ7-router"
  dns_servers = ["10.33.16.100", "8.8.8.8"]
  pubnet_name = "ext_net"
  image_name  = "ubuntu-22.04-jammy-server-cloud-image-amd64"
  flavor_name = "m1.small"
}

# Define OpenStack provider
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  cloud       = "openstack"
  cacert_file = local.cacert_file
}



###########################################################################
#
# create keypairs
#
###########################################################################

# import keypair, if public_key is not specified, create new keypair to use
resource "openstack_compute_keypair_v2" "terraform-keypair" {
  name       = "my-terraform-pubkey"
  public_key = file("~/.ssh/id_rsa_OpenStackHsFulda.pub")
}

##########################################################################
# generate an SSH keypair for communication of deployment instance with others
resource "tls_private_key" "deployment_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create an OpenStack keypair resource from the Terraform-generated public key
resource "openstack_compute_keypair_v2" "bastion_keypair" {
  name       = "delpoyment_ssh_key"
  public_key = tls_private_key.deployment_key.public_key_openssh
}





###########################################################################
#
# create security group
#
###########################################################################

resource "openstack_networking_secgroup_v2" "terraform-secgroup" {
  name        = "my-terraform-secgroup"
  description = "for terraform instances"
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-http" {
  direction      = "ingress"
  ethertype      = "IPv4"
  protocol       = "tcp"
  port_range_min = 80
  port_range_max = 80
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ssh" {
  direction      = "ingress"
  ethertype      = "IPv4"
  protocol       = "tcp"
  port_range_min = 22
  port_range_max = 22
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}


###########################################################################
#
# create network
#
###########################################################################

resource "openstack_networking_network_v2" "terraform-network-1" {
  name           = "my-terraform-network-1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-subnet-1" {
  name            = "my-terraform-subnet-1"
  network_id      = openstack_networking_network_v2.terraform-network-1.id
  cidr            = "192.168.255.0/24"
  ip_version      = 4
  dns_nameservers = local.dns_servers
}

data "openstack_networking_router_v2" "router-1" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.router-1.id
  subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}



###########################################################################
#
# create backend instances
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-backend-instances" {
  count           = 2
  name            = "vaultwarden-backend-instance-${count.index + 1}"
  image_name      = local.image_name
  flavor_name     = local.flavor_name
  key_pair        = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }
  user_data = templatefile("${path.module}/scripts/dummyLoadBalancer.tpl", {
    instance_number = count.index + 1
    public_key      = tls_private_key.deployment_key.public_key_openssh
  })
}

locals {
  backend_private_ip_list = [for instance in openstack_compute_instance_v2.vaultwarden-backend-instances : instance.network[0].fixed_ip_v4]
  backend-instance_names  = [for instance in openstack_compute_instance_v2.vaultwarden-backend-instances : instance.name]
}

###########################################################################
#
# create deployment instances
#
###########################################################################

resource "openstack_compute_instance_v2" "vaultwarden-deployment-instance" {
  name            = "vaultwarden-deployment-instance"
  image_name      = local.image_name
  flavor_name     = "m1.large"
  key_pair        = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }
  user_data = templatefile("${path.module}/scripts/deployment_cloudinit_script.tpl", {
    public_key               = tls_private_key.deployment_key.public_key_openssh
    private_key              = tls_private_key.deployment_key.private_key_openssh
    backend_private_ip_list  = local.backend_private_ip_list
    frontend_private_ip_list = local.frontend_private_ip_list
  })
}

# # Allocate a floating IP from the external network pool
# resource "openstack_networking_floatingip_v2" "vaultwarden_floating_ip" {
#   pool = local.pubnet_name
# }

# # Associate the floating IP with the instance's port
# resource "openstack_networking_floatingip_associate_v2" "vaultwarden_fip_assoc" {
#   floating_ip = openstack_networking_floatingip_v2.vaultwarden_floating_ip.address
#   port_id     = openstack_compute_instance_v2.vaultwarden-test-terraform-instance-3.network.0.port
# }


###########################################################################
#
# create frontend instances
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-frontend-instances" {
  count           = 2
  name            = "vaultwarden-frontend-instance-${count.index + 1}"
  image_name      = local.image_name
  flavor_name     = local.flavor_name
  key_pair        = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }
  user_data = file("${path.module}/scripts/dummyLoadBalancer.tpl")
}

locals {
  frontend_private_ip_list = [for instance in openstack_compute_instance_v2.vaultwarden-frontend-instances : instance.network[0].fixed_ip_v4]
  frontend-instance_names  = [for instance in openstack_compute_instance_v2.vaultwarden-frontend-instances : instance.name]
}



###########################################################################
#
# create load balancer for backend instances
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb-backend" {
  name          = "lb-backend"
  vip_subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}

resource "openstack_lb_listener_v2" "listener-backend" {
  protocol         = "HTTP"
  protocol_port    = 80
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-backend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-backend" {
  name        = "pool-backend"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener-backend.id
}

resource "openstack_lb_members_v2" "members-backend" {
  pool_id  = openstack_lb_pool_v2.pool-backend.id
  for_each = { for idx, name in local.backend-instance_names : name => idx } # Create a map of names to their index

  member {
    name          = each.key
    address       = openstack_compute_instance_v2.vaultwarden-backend-instances[each.value].access_ip_v4
    protocol_port = 80
    backup        = each.key == 2 ? true : false
  }
}

resource "openstack_lb_monitor_v2" "monitor-backend" {
  pool_id        = openstack_lb_pool_v2.pool-backend.id
  type           = "HTTP"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = 200

  depends_on = [openstack_lb_loadbalancer_v2.lb-backend, openstack_lb_listener_v2.listener-backend, openstack_lb_pool_v2.pool-backend, openstack_lb_members_v2.members-backend]
}


###########################################################################
#
# create load balancer for backend instances
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb-frontend" {
  name          = "lb-frontend"
  vip_subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}

resource "openstack_lb_listener_v2" "listener-frontend" {
  protocol         = "HTTP"
  protocol_port    = 80
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-frontend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-frontend" {
  name        = "pool-frontend"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener-frontend.id
}

resource "openstack_lb_members_v2" "members-frontend" {
  pool_id  = openstack_lb_pool_v2.pool-frontend.id
  for_each = { for idx, name in local.frontend-instance_names : name => idx } # Create a map of names to their index

  member {
    name          = each.key
    address       = openstack_compute_instance_v2.vaultwarden-frontend-instances[each.value].access_ip_v4
    protocol_port = 80
    backup        = each.key == 2 ? true : false
  }
}

resource "openstack_lb_monitor_v2" "monitor-frontend" {
  pool_id        = openstack_lb_pool_v2.pool-frontend.id
  type           = "HTTP"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = 200

  depends_on = [openstack_lb_loadbalancer_v2.lb-frontend, openstack_lb_listener_v2.listener-frontend, openstack_lb_pool_v2.pool-frontend, openstack_lb_members_v2.members-frontend]

}


###########################################################################
#
# assign floating ip to load balancers
#
###########################################################################
resource "openstack_networking_floatingip_v2" "fip-backend" {
  pool    = local.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb-backend.vip_port_id
}

resource "openstack_networking_floatingip_v2" "fip-frontend" {
  pool    = local.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb-frontend.vip_port_id
}



output "backend_vip_addr" {
  value = openstack_networking_floatingip_v2.fip-backend
}

output "frontent_vip_addr" {
  value = openstack_networking_floatingip_v2.fip-frontend
}

output "backend_private_IPs" {
  value = local.backend_private_ip_list
}

output "backend_instance_names" {
  value = local.backend-instance_names
}

output "frontend_private_IPs" {
  value = local.frontend_private_ip_list
}

output "frontend_instance_names" {
  value = local.frontend-instance_names
}
