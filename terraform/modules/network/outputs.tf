output "network_id" {
  value = openstack_networking_network_v2.terraform-network-1.id
}

output "subnet_id" {
  value = openstack_networking_subnet_v2.terraform-subnet-1.id
}
