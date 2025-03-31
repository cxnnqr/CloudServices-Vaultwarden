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
# loadbalancer for frontend instances
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb-frontend" {
  name          = "lb-frontend"
  vip_subnet_id = var.subnet_id
}

resource "openstack_lb_listener_v2" "listener-frontend" {
  protocol         = var.frontend_protocol
  protocol_port    = var.frontend_protocol_port
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-frontend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-frontend" {
  name        = "pool-frontend"
  protocol    = var.frontend_protocol
  lb_method   = var.frontend_lb_method
  listener_id = openstack_lb_listener_v2.listener-frontend.id
}

resource "openstack_lb_members_v2" "members-frontend" {
  pool_id = openstack_lb_pool_v2.pool-frontend.id
  dynamic "member" {
    for_each = var.frontend_instances
    content {
      name          = member.value.name
      address       = member.value.access_ip_v4
      protocol_port = var.frontend_protocol_port
      subnet_id     = var.subnet_id
    }
  }
}

resource "openstack_lb_monitor_v2" "monitor-frontend" {
  pool_id        = openstack_lb_pool_v2.pool-frontend.id
  type           = "HTTPS"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = "200,301"
  admin_state_up = true
}

resource "openstack_networking_floatingip_v2" "fip-frontend" {
  pool    = var.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb-frontend.vip_port_id
}


