output "backend_vip_addr" {
  value       = module.loadbalancer.backend_vip_addr
  description = "IP address of the backend load balancer"
}

output "frontend_vip_addr" {
  value       = module.loadbalancer.frontend_vip_addr
  description = "IP address of the frontend load balancer"
}

output "deployment_floating_ip" {
  value       = module.compute.deployment_floating_ip
  description = "floating IP of the deployment instance"
}
