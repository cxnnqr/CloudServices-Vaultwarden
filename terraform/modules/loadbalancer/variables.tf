# general Variables
variable "subnet_id" {
  description = "ID of the subnet where the load balancer will be created"
  type        = string
}

variable "pubnet_name" {
  description = "Name of the public network"
  type        = string
}

# Backend Load Balancer Variables
variable "backend_protocol" {
  description = "Protocol for backend load balancer (e.g., HTTP, TCP)"
  type        = string
  default     = "HTTP"
}

variable "backend_protocol_port" {
  description = "Port number for backend protocol"
  type        = number
  default     = 80
}

variable "backend_lb_method" {
  description = "Load balancing method for backend (e.g., ROUND_ROBIN, SOURCE_IP, LEAST_CONNECTIONS)"
  type        = string
  default     = "ROUND_ROBIN"
}

variable "backend_instances" {
  description = "Map of backend instances to load balance"
  type        = map(any)
}

# Frontend Load Balancer Variables
variable "frontend_protocol" {
  description = "Protocol for frontend load balancer (e.g., HTTP, TCP)"
  type        = string
  default     = "TCP"
}

variable "frontend_protocol_port" {
  description = "Port number for frontend protocol"
  type        = number
  default     = 443
}

variable "frontend_lb_method" {
  description = "Load balancing method for frontend (e.g., ROUND_ROBIN, SOURCE_IP)"
  type        = string
  default     = "ROUND_ROBIN"
}

variable "frontend_instances" {
  description = "Map of frontend instances to load balance"
  type        = map(any)
}
