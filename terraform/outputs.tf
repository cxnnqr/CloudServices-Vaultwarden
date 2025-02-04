output "backend_vip_addr" {
  value       = module.loadbalancer.backend_vip_addr
  description = "IP address of the backend load balancer"
}

output "frontend_vip_addr" {
  value       = module.loadbalancer.frontend_vip_addr
  description = "IP address of the frontend load balancer"
}
