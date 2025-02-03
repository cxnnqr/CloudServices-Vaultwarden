output "terraform_keypair_name" {
  value = openstack_compute_keypair_v2.terraform-keypair.name
}

output "deployment_public_key" {
  value = tls_private_key.deployment_key.public_key_openssh
}

output "deployment_private_key" {
  value = tls_private_key.deployment_key.private_key_openssh
}
