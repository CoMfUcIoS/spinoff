locals {
  non_sensitive_password = nonsensitive(random_password.password.result)
}

output "gateway_url" {
  value = "http://${hcloud_server.faasd_node.ipv4_address}:8080"
}

output "password" {
  value     = local.non_sensitive_password
  sensitive = false
}

output "login_cmd" {
  value     = "faas-cli login -g http://${hcloud_server.faasd_node.ipv4_address}:8080 -p ${local.non_sensitive_password}"
  sensitive = false
}
