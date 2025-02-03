variable "group_name" {
  type        = string
  description = "name of the group project"
  default     = "<GroupName>"
}

variable "public_key" {
  type        = string
  description = "path to the public ssh key"
  default     = "~/.ssh/public_key.pub"
}

variable "cacert_file" {
  type        = string
  description = "Path to the CA certificate file"
  default     = "../os-trusted-cas"
}

variable "pubnet_name" {
  description = "Name of the public network"
  type        = string
}

variable "dns_servers" {
  type    = list(string)
  default = ["10.33.16.100", "8.8.8.8"]
}

variable "router_name" {
  type    = string
  default = "CloudServX-router"
}

variable "global_image_name" {
  type        = string
  description = "Name of the image to use for all the instances"
}

variable "backend_instance_count" {
  type        = number
  description = "Number of backend instances to create"
  default     = 2
}

variable "frontend_instance_count" {
  type        = number
  description = "Number of frontend instances to create"
  default     = 2
}
