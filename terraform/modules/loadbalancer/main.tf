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
# loadbalancer for backend instances
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb-backend" {
  name          = "lb-backend"
  vip_subnet_id = var.subnet_id
}

resource "openstack_lb_listener_v2" "listener-backend" {
  protocol         = var.backend_protocol
  protocol_port    = var.backend_protocol_port
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb-backend.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool-backend" {
  name        = "pool-backend"
  protocol    = var.backend_protocol
  lb_method   = var.backend_lb_method
  listener_id = openstack_lb_listener_v2.listener-backend.id
}

resource "openstack_lb_members_v2" "members-backend" {
  pool_id = openstack_lb_pool_v2.pool-backend.id
  dynamic "member" {
    for_each = var.backend_instances
    content {
      name          = member.value.name
      address       = member.value.access_ip_v4
      protocol_port = var.backend_protocol_port
      subnet_id     = var.subnet_id
      backup        = index(keys(var.backend_instances), member.key) == length(var.backend_instances) - 1 ? true : false
    }
  }
}

resource "openstack_lb_monitor_v2" "monitor-backend" {
  pool_id        = openstack_lb_pool_v2.pool-backend.id
  type           = var.backend_protocol
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = 200
}

resource "openstack_networking_floatingip_v2" "fip-backend" {
  pool    = var.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb-backend.vip_port_id
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
  type           = var.frontend_protocol
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = 200
}

resource "openstack_networking_floatingip_v2" "fip-frontend" {
  pool    = var.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb-frontend.vip_port_id
}
