terraform {
  required_providers {
    hcloud = {
      source  = "registry.opentofu.org/hetznercloud/hcloud"
      version = "1.49.1"
    }
    external = {
      source  = "registry.opentofu.org/hashicorp/external"
      version = "2.0.0"
    }
    local = {
      source  = "registry.opentofu.org/hashicorp/local"
      version = "2.5.2"
    }
    random = {
      source  = "registry.opentofu.org/hashicorp/random"
      version = "3.6.3"
    }
    template = {
      source  = "registry.opentofu.org/hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "external" {
}
