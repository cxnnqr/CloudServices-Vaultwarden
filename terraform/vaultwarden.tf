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
# create compute instances (deployment, backend, frontend)
#
###########################################################################

module "compute" {
  # general variables
  source                 = "./modules/compute"
  terraform_keypair_name = module.keypairs.terraform_keypair_name
  secgroup_name          = module.security.secgroup_name
  network_id             = module.network.network_id
  deployment_public_key  = module.keypairs.deployment_public_key
  # backend variables
  backend_instance_count = var.backend_instance_count
  backend_image_name     = var.global_image_name
  backend_flavor_name    = "m1.small"
  # frontend variables
  frontend_instance_count = var.frontend_instance_count
  frontend_image_name     = var.global_image_name
  frontend_flavor_name    = "m1.small"
  # deployment variables
  deployment_image_name    = var.global_image_name
  deployment_flavor_name   = "m1.large"
  deployment_private_key   = module.keypairs.deployment_private_key
  backend_private_ip_list  = module.compute.backend_private_ip_list
  frontend_private_ip_list = module.compute.frontend_private_ip_list

  depends_on = [module.network]
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
  pool_id = openstack_lb_pool_v2.pool-backend.id
  dynamic "member" {
    for_each = module.compute.backend_instances
    content {
      name          = member.value.name
      address       = member.value.access_ip_v4
      protocol_port = 80
      subnet_id     = module.network.subnet_id
      backup        = index(keys(module.compute.backend_instances), member.key) == length(module.compute.backend_instances) - 1 ? true : false
    }
  }
  depends_on = [module.compute]
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

  depends_on = [openstack_lb_loadbalancer_v2.lb-backend, openstack_lb_listener_v2.listener-backend, openstack_lb_pool_v2.pool-backend, openstack_lb_members_v2.members-backend, module.compute]
}

###########################################################################
#
# create load balancer for frontend instances
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb-frontend" {
  name          = "lb-frontend"
  vip_subnet_id = module.network.subnet_id
}

resource "openstack_lb_listener_v2" "listener-frontend" {
  protocol         = "TCP"
  protocol_port    = 80 #443
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-frontend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-frontend" {
  name        = "pool-frontend"
  protocol    = "HTTP"        #"TCP"
  lb_method   = "ROUND_ROBIN" #"SOURCE_IP"
  listener_id = openstack_lb_listener_v2.listener-frontend.id
}

resource "openstack_lb_members_v2" "members-frontend" {
  pool_id = openstack_lb_pool_v2.pool-frontend.id
  dynamic "member" {
    for_each = module.compute.frontend_instances
    content {
      name          = member.value.name
      address       = member.value.access_ip_v4
      protocol_port = 80 #443
      subnet_id     = module.network.subnet_id
    }
  }
  depends_on = [module.compute]
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

  depends_on = [openstack_lb_loadbalancer_v2.lb-frontend, openstack_lb_listener_v2.listener-frontend, openstack_lb_pool_v2.pool-frontend, openstack_lb_members_v2.members-frontend, module.compute]

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

