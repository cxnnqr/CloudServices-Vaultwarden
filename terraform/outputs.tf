output "backend_vip_addr" {
  value       = openstack_networking_floatingip_v2.fip-backend.address
  description = "IP address of the backend load balancer"
}

output "frontend_vip_addr" {
  value       = openstack_networking_floatingip_v2.fip-frontend.address
  description = "IP address of the frontend load balancer"
}

output "backend_private_IPs" {
  value       = local.backend_private_ip_list
  description = "list of private IP addresses of the backend instances"
}

output "backend_instance_names" {
  value       = local.backend-instance_names
  description = "list of names of the backend instances"
}

output "frontend_private_IPs" {
  value       = local.frontend_private_ip_list
  description = "list of private IP addresses of the frontend instances"
}

output "frontend_instance_names" {
  value       = local.frontend-instance_names
  description = "list of names of the frontend instances"
}




