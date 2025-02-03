output "backend_vip_addr" {
  value       = module.loadbalancer.backend_vip_addr
  description = "IP address of the backend load balancer"
}

output "frontend_vip_addr" {
  value       = module.loadbalancer.frontend_vip_addr
  description = "IP address of the frontend load balancer"
}

output "backend_private_IPs" {
  value       = module.compute.backend_private_ip_list
  description = "list of private IP addresses of the backend instances"
}

output "backend_instance_names" {
  value       = module.compute.backend_instance_names
  description = "list of names of the backend instances"
}

output "frontend_private_IPs" {
  value       = module.compute.frontend_private_ip_list
  description = "list of private IP addresses of the frontend instances"
}

output "frontend_instance_names" {
  value       = module.compute.frontend_instance_names
  description = "list of names of the frontend instances"
}
