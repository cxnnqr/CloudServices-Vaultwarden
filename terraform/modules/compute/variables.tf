###########################################################################
#
# general
#
###########################################################################
variable "terraform_keypair_name" {
  description = "Name of the OpenStack keypair to use for SSH access"
  type        = string
}

variable "secgroup_name" {
  description = "Name of the security group to apply to the instances"
  type        = string
}

variable "network_id" {
  description = "UUID of the network to attach the instances to"
  type        = string
}

variable "deployment_public_key" {
  description = "Public key to be used for deployment"
  type        = string
}

variable "pubnet_name" {
  description = "Name of the public network"
  type        = string
}

###########################################################################
#
# deployment
#
###########################################################################
variable "deployment_image_name" {
  description = "Name of the image to use for the deployment instance"
  type        = string
  default     = "ubuntu-22.04-jammy-server-cloud-image-amd64"
}

variable "deployment_flavor_name" {
  description = "Name of the flavor to use for the deployment instance. OPTIONS: m1.small, m1.medium, m1.large"
  type        = string
  default     = "m1.small"
}

variable "deployment_private_key" {
  description = "Private key for deployment instance"
  type        = string
}

variable "backend_private_ip_list" {
  description = "List of private IPs for backend instances"
  type        = list(string)
}

variable "master_database_private_ip" {
  description = "Private IP for master database instance"
  type        = string
}

variable "database_private_ip_list" {
  description = "List of private IPs for database instances"
  type        = list(string)
}

variable "frontend_private_ip_list" {
  description = "List of private IPs for frontend instances"
  type        = list(string)
}

variable "ANSIBLE_VAULT_PASSWORD" {
  type = string
}

variable "ANSIBLE_BECOME_PASSWORD" {
  type = string
}

###########################################################################
#
# backend
#
###########################################################################
variable "backend_instance_count" {
  description = "Number of backend instances to create"
  type        = number
  default     = 2
}

variable "backend_image_name" {
  description = "Name of the image to use for the instances"
  type        = string
  default     = "ubuntu-22.04-jammy-server-cloud-image-amd64"
}

variable "backend_flavor_name" {
  description = "Name of the flavor/instance type to use. OPTIONS: m1.small, m1.medium, m1.large"
  type        = string
  default     = "m1.small"
}

###########################################################################
#
# database
#
###########################################################################
variable "slave_database_instance_count" {
  description = "Number of slave database instances to create"
  type        = number
  default     = 2
}

variable "database_image_name" {
  description = "Name of the image to use for the instances"
  type        = string
  default     = "ubuntu-22.04-jammy-server-cloud-image-amd64"
}

variable "database_flavor_name" {
  description = "Name of the flavor/instance type to use. OPTIONS: m1.small, m1.medium, m1.large"
  type        = string
  default     = "m1.small"
}


###########################################################################
#
# frontend
#
###########################################################################
variable "frontend_instance_count" {
  description = "Number of frontend instances to create"
  type        = number
  default     = 2
}

variable "frontend_image_name" {
  description = "Name of the image to use for frontend instances"
  type        = string
  default     = "ubuntu-22.04-jammy-server-cloud-image-amd64"
}

variable "frontend_flavor_name" {
  description = "Name of the flavor to use for frontend instances. OPTIONS: m1.small, m1.medium, m1.large"
  type        = string
  default     = "m1.small"
}


