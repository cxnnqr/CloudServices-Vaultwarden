terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

resource "openstack_networking_secgroup_v2" "terraform-secgroup" {
  name        = var.secgroup_name
  description = var.secgroup_description
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-http" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ssh" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-prometheus" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9090
  port_range_max    = 9090
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-node-exporter" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9100
  port_range_max    = 9100
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-loki" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3100
  port_range_max    = 3100
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-grafana" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3000
  port_range_max    = 3000
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-TCP" {
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
}
