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

variable "dns_servers" {
  type    = list(string)
  default = ["10.33.16.100", "8.8.8.8"]
}

variable "router_name" {
  type    = string
  default = "CloudServX-router"
}

