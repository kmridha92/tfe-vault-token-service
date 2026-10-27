terraform {
  required_version = ">= 1.5"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
  }
}

provider "tfe" {
  hostname = trimprefix(var.tfe_address, "https://")
  token    = var.tfe_admin_token
}

provider "vault" {
  address = var.vault_addr
  # Token is read from the VAULT_TOKEN environment variable.
}
