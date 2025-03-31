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


  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/vaultwarden_cloudinit_script.tpl", {
    instance_number = count.index + 1
    public_key      = var.deployment_public_key
  })
}

###########################################################################
#
# database instances
#
###########################################################################
resource "openstack_compute_instance_v2" "vaultwarden-database-instances" {
  count           = var.database_instance_count
  name            = "vaultwarden-database-instance-${count.index + 1}"
  image_name      = var.database_image_name
  flavor_name     = var.database_flavor_name
  key_pair        = var.terraform_keypair_name
  security_groups = [var.secgroup_name]


  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/vaultwarden_cloudinit_script.tpl", {
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



  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/vaultwarden_cloudinit_script.tpl", {
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


  network {
    uuid = var.network_id
  }
  user_data = templatefile("${path.module}/scripts/deployment_cloudinit_script.tpl", {
    public_key               = var.deployment_public_key
    private_key              = var.deployment_private_key
    backend_private_ip_list  = var.backend_private_ip_list
    database_private_ip_list = var.database_private_ip_list
    frontend_private_ip_list = var.frontend_private_ip_list
    ANSIBLE_VAULT_PASSWORD   = var.ANSIBLE_VAULT_PASSWORD
    ANSIBLE_BECOME_PASSWORD  = var.ANSIBLE_BECOME_PASSWORD
    access_network           = true
  })
}
# allocate and associate a floating IP to the deployment instance
resource "openstack_networking_floatingip_v2" "deployment_floating_ip" {
  pool = var.pubnet_name
}

data "openstack_networking_port_v2" "deployment_port" {
  fixed_ip = openstack_compute_instance_v2.vaultwarden-deployment-instance.network[0].fixed_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "deployment_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.deployment_floating_ip.address
  port_id     = data.openstack_networking_port_v2.deployment_port.id
}
