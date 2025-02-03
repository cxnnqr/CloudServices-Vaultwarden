###########################################################################
#
# backend outputs
#
###########################################################################
output "backend_instances" {
  description = "private IPs, access IPs and names of the backend instances"
  value = { for idx, instance in openstack_compute_instance_v2.vaultwarden-backend-instances : idx => {
    name         = instance.name
    access_ip_v4 = instance.access_ip_v4
    private_ip   = instance.network[0].fixed_ip_v4
  } }
}

output "backend_instance_names" {
  description = "names of the backend instances"
  value       = openstack_compute_instance_v2.vaultwarden-backend-instances[*].name
}

output "backend_private_ip_list" {
  description = "private IPs of the backend instances"
  value       = openstack_compute_instance_v2.vaultwarden-backend-instances[*].network[0].fixed_ip_v4
}

###########################################################################
#
# frontend outputs
#
###########################################################################
output "frontend_instances" {
  description = "private IPs, access IPs and names of the frontend instances"
  value = { for idx, instance in openstack_compute_instance_v2.vaultwarden-frontend-instances : idx => {
    name         = instance.name
    access_ip_v4 = instance.access_ip_v4
    private_ip   = instance.network[0].fixed_ip_v4
  } }
}

output "frontend_instance_names" {
  description = "names of the frontend instances"
  value       = openstack_compute_instance_v2.vaultwarden-frontend-instances[*].name
}

output "frontend_private_ip_list" {
  description = "private IPs of the frontend instances"
  value       = openstack_compute_instance_v2.vaultwarden-frontend-instances[*].network[0].fixed_ip_v4
}
