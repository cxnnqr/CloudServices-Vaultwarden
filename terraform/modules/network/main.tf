terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}


resource "openstack_networking_network_v2" "terraform-network-1" {
  name           = var.network_name
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-subnet-1" {
  name            = var.subnet_name
  network_id      = openstack_networking_network_v2.terraform-network-1.id
  cidr            = var.cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

data "openstack_networking_router_v2" "router" {
  name = var.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = data.openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}
