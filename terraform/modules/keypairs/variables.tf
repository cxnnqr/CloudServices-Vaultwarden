variable "terraform_keypair_name" {
  type        = string
  description = "name of the terraform keypair"
}

variable "terraform_public_key_path" {
  type        = string
  description = "path to the public ssh key"
  default     = "~/.ssh/public_key.pub"
}

variable "deployment_keypair_name" {
  type        = string
  description = "name of the deployment keypair"
}
