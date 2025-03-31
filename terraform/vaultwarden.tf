# Define OpenStack project config etc.
locals {
  cacert_file = "../os-trusted-cas"                           #!!!
  router_name = "CloudServ7-router"                           #!!!
  dns_servers = ["10.33.16.100", "8.8.8.8"]                   #!!!
  pubnet_name = "ext_net"                                     #!!!
  image_name  = "ubuntu-22.04-jammy-server-cloud-image-amd64" #!!!
  flavor_name = "m1.small"                                    #!!!
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
  dns_nameservers = var.dns_nameservers
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
  pubnet_name            = var.pubnet_name
  # backend variables
  backend_instance_count = var.backend_instance_count
  backend_image_name     = var.global_image_name
  backend_flavor_name    = "m1.small"
  #database instances
  slave_database_instance_count = var.slave_database_instance_count
  database_image_name           = var.global_image_name
  database_flavor_name          = "m1.small"
  # frontend variables
  frontend_instance_count = var.frontend_instance_count
  frontend_image_name     = var.global_image_name
  frontend_flavor_name    = "m1.small"
  # deployment variables
  deployment_image_name      = var.global_image_name
  deployment_flavor_name     = "m1.medium"
  deployment_private_key     = module.keypairs.deployment_private_key
  backend_private_ip_list    = module.compute.backend_private_ip_list
  master_database_private_ip = module.compute.master_database_private_ip
  database_private_ip_list   = module.compute.database_private_ip_list
  frontend_private_ip_list   = module.compute.frontend_private_ip_list

  depends_on = [module.network]
}

###########################################################################
#
# create load balancers (frontend)
#
###########################################################################
module "loadbalancer" {
  # general variables
  source      = "./modules/loadbalancer"
  pubnet_name = var.pubnet_name
  subnet_id   = module.network.subnet_id
  # frontend variables
  frontend_instances     = module.compute.frontend_instances
  frontend_protocol      = "TCP"       #"TCP" ----> Set to TCP for production
  frontend_protocol_port = 443         #443 ----> Set to 443 for production
  frontend_lb_method     = "SOURCE_IP" #"SOURCE_IP" ----> Set to SOURCE_IP for production
}
