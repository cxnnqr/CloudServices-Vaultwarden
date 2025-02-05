output "frontend_vip_addr" {
  value       = module.loadbalancer.frontend_vip_addr
  description = "public IP address of the frontend load balancer"
}

output "deployment_floating_ip" {
  value       = module.compute.deployment_floating_ip
  description = "public IP address of the deployment instance"
}
