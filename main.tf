# First try to get all SSH keys
data "hcloud_ssh_keys" "all" {}

locals {
  # Check if key with our desired name already exists
  key_exists = contains([for key in data.hcloud_ssh_keys.all.ssh_keys : key.name], var.ssh_key_name)
}

# Create key only if it doesn't exist
resource "hcloud_ssh_key" "default" {
  count      = local.key_exists ? 0 : 1
  name       = var.ssh_key_name
  public_key = file(pathexpand("~/.ssh/id_terraform_rsa.pub"))
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_-#"
}

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-config.tpl")
  vars = {
    gw_password  = random_password.password.result
    ssh_key      = data.local_file.ssh_key.content
    docker_user  = var.docker_user
    hcloud_token = var.hcloud_token
  }
}

data "local_file" "ssh_key" {
  filename = pathexpand(var.ssh_key_file)
}

resource "hcloud_server" "faasd_node" {
  name        = var.faasd_node_name
  image       = "debian-12"
  server_type = var.faasd_node_server_type
  location    = var.faasd_node_location
  
  # Reference the SSH key name directly since we know it exists (either pre-existing or just created)
  ssh_keys = [var.ssh_key_name]
  
  user_data = data.template_file.cloud_init.rendered

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = file(pathexpand("~/.ssh/id_terraform_rsa"))
    }
    
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait --long",
      "echo 'Completed cloud-init!'"
    ]
  }
}
