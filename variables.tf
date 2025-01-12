variable "ssh_key_name" {
  description = "The name of the SSH key"
  type        = string
  default     = "faas-node-ssh-key"
}

variable "ssh_key_file" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_terraform_rsa.pub"
}

variable "docker_user" {
  default     = "comfucios"
  description = "Docker username"
  type        = string
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "faasd_node_name" {
  default     = "faasd-node"
  description = "Name of the faasd node"
  type        = string
}

variable "faasd_node_server_type" {
  default     = "cx22"
  description = "Server type for the faasd node"
  type        = string
}

variable "faasd_node_location" {
  default     = "nbg1"
  description = "Location for the faasd node"
  type        = string
}
