output "backend_vip_addr" {
  description = "IP address of the backend load balancer"
  value       = openstack_networking_floatingip_v2.fip-backend.address
}

output "frontend_vip_addr" {
  description = "IP address of the frontend load balancer"
  value       = openstack_networking_floatingip_v2.fip-frontend.address
}
