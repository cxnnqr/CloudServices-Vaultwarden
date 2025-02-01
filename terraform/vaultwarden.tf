# Define OpenStack project config etc.
locals {
  cacert_file = "../os-trusted-cas"         #!!!
  router_name = "CloudServ7-router"         #!!!
  dns_servers = ["10.33.16.100", "8.8.8.8"] #!!!
  pubnet_name = "ext_net"
  image_name  = "ubuntu-22.04-jammy-server-cloud-image-amd64"
  flavor_name = "m1.small"
}

###########################################################################
#
# create keypairs
#
###########################################################################

module "keypairs" {
  source                    = "./modules/keypairs"
  terraform_keypair_name    = "${var.group_name}-terraform-pubkey"
  terraform_public_key_path = var.public_key
  deployment_keypair_name   = "deployment_ssh_key"
}

###########################################################################
#
# create security group
#
###########################################################################

module "security" {
  source               = "./modules/security"
  secgroup_name        = "${var.group_name}-terraform-secgroup"
  secgroup_description = "for terraform instances"
}

###########################################################################
#
# create network
#
###########################################################################

module "network" {
  source          = "./modules/network"
  network_name    = "${var.group_name}-terraform-network-1"
  subnet_name     = "${var.group_name}-terraform-subnet-1"
  cidr            = "192.168.255.0/24"
  dns_nameservers = var.dns_servers
  router_name     = var.router_name
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
  key_pair        = module.keypairs.terraform_keypair_name
  security_groups = [module.security.secgroup_name]

  depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = module.network.network_id
  }
  user_data = templatefile("${path.module}/scripts/dummyLoadBalancer.tpl", {
    instance_number = count.index + 1
    public_key      = module.keypairs.deployment_public_key
  })
}

locals {
  backend_private_ip_list = [for instance in openstack_compute_instance_v2.vaultwarden-backend-instances : instance.network[0].fixed_ip_v4]
  backend-instance_names  = [for instance in openstack_compute_instance_v2.vaultwarden-backend-instances : instance.name]
}

###########################################################################
#
# create deployment instance
#
###########################################################################

resource "openstack_compute_instance_v2" "vaultwarden-deployment-instance" {
  name            = "vaultwarden-deployment-instance"
  image_name      = local.image_name
  flavor_name     = "m1.large"
  key_pair        = module.keypairs.terraform_keypair_name
  security_groups = [module.security.secgroup_name]

  depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = module.network.network_id
  }
  user_data = templatefile("${path.module}/scripts/deployment_cloudinit_script.tpl", {
    public_key               = module.keypairs.deployment_public_key
    private_key              = module.keypairs.deployment_private_key
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
  key_pair        = module.keypairs.terraform_keypair_name
  security_groups = [module.security.secgroup_name]

  depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = module.network.network_id
  }
  user_data = templatefile("${path.module}/scripts/dummyLoadBalancer.tpl", {
    instance_number = count.index + 1
    public_key      = module.keypairs.deployment_public_key
  })
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
  vip_subnet_id = module.network.subnet_id
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
  vip_subnet_id = module.network.subnet_id
}

resource "openstack_lb_listener_v2" "listener-frontend" {
  protocol         = "TCP"
  protocol_port    = 443
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-frontend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-frontend" {
  name        = "pool-frontend"
  protocol    = "TCP"
  lb_method   = "SOURCE_IP"
  listener_id = openstack_lb_listener_v2.listener-frontend.id
}

resource "openstack_lb_members_v2" "members-frontend" {
  pool_id  = openstack_lb_pool_v2.pool-frontend.id
  for_each = { for idx, name in local.frontend-instance_names : name => idx } # Create a map of names to their index

  member {
    name          = each.key
    address       = openstack_compute_instance_v2.vaultwarden-frontend-instances[each.value].access_ip_v4
    protocol_port = 443
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


# output "backend_vip_addr" {
#   value = openstack_networking_floatingip_v2.fip-backend.address
# }

# output "frontent_vip_addr" {
#   value = openstack_networking_floatingip_v2.fip-frontend.address
# }

# output "backend_private_IPs" {
#   value = local.backend_private_ip_list
# }

# output "backend_instance_names" {
#   value = local.backend-instance_names
# }

# output "frontend_private_IPs" {
#   value = local.frontend_private_ip_list
# }

# output "frontend_instance_names" {
#   value = local.frontend-instance_names
# }
