terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

###########################################################################
#
# backend instances
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-backend-instances" {
  count           = var.backend_instance_count
  name            = "vaultwarden-backend-instance-${count.index + 1}"
  image_name      = var.backend_image_name
  flavor_name     = var.backend_flavor_name
  key_pair        = var.terraform_keypair_name
  security_groups = [var.secgroup_name]

  #   depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/dummyLoadBalancer.tpl", {
    instance_number = count.index + 1
    public_key      = var.deployment_public_key
  })
}

###########################################################################
#
# frontend instances
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-frontend-instances" {
  count           = var.frontend_instance_count
  name            = "vaultwarden-frontend-instance-${count.index + 1}"
  image_name      = var.frontend_image_name
  flavor_name     = var.frontend_flavor_name
  key_pair        = var.terraform_keypair_name
  security_groups = [var.secgroup_name]

  #   depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/dummyLoadBalancer.tpl", {
    instance_number = count.index + 1
    public_key      = var.deployment_public_key
  })
}

###########################################################################
#
# deployment instance
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-deployment-instance" {
  name            = "vaultwarden-deployment-instance"
  image_name      = var.deployment_image_name
  flavor_name     = var.deployment_flavor_name
  key_pair        = var.terraform_keypair_name
  security_groups = [var.secgroup_name]

  #   depends_on = [module.network.openstack_networking_subnet_v2]

  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/deployment_cloudinit_script.tpl", {
    public_key               = var.deployment_public_key
    private_key              = var.deployment_private_key
    backend_private_ip_list  = var.backend_private_ip_list
    frontend_private_ip_list = var.frontend_private_ip_list
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
