variable "network_name" {
  type        = string
  description = "name of the network"
}

variable "subnet_name" {
  type        = string
  description = "name of the subnet"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the subnet"
  default     = "192.168.255.0/24"
}

variable "dns_nameservers" {
  type        = list(string)
  description = "DNS nameservers for the subnet"
  default     = ["10.33.16.100", "8.8.8.8"]
}

variable "router_name" {
  type        = string
  description = "name of the router"
}

