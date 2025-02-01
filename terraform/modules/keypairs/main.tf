terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

# keypair to use for terraform
resource "openstack_compute_keypair_v2" "terraform-keypair" {
  name       = var.terraform_keypair_name
  public_key = file(var.terraform_public_key_path)
}

# generate an SSH keypair for communication of deployment instance with other instances
resource "tls_private_key" "deployment_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create an OpenStack keypair resource from the Terraform-generated public key
resource "openstack_compute_keypair_v2" "bastion_keypair" {
  name       = var.deployment_keypair_name
  public_key = tls_private_key.deployment_key.public_key_openssh
}
