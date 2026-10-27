variable "vault_addr" {
  description = "Vault address."
  type        = string
  default     = "http://127.0.0.1:8200"
}

variable "tfe_address" {
  description = "Terraform Enterprise / HCP Terraform address."
  type        = string
  default     = "https://app.terraform.io"
}

variable "tfe_admin_token" {
  description = "Token Vault uses to mint tokens (HCP Terraform user token or TFE admin token)."
  type        = string
  sensitive   = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization in which the teams are created."
  type        = string
}

variable "teams" {
  description = "Teams to create in HCP Terraform. Each gets a one-to-one Vault role, policy, AppRole and GitHub OIDC role. github_repository defaults to var.github_repository."
  type = map(object({
    github_repository = optional(string)
  }))
  default = {
    team1 = {}
    team2 = {}
    team3 = {}
  }
}

variable "token_ttl" {
  description = "Default TTL of minted tokens, in seconds."
  type        = number
  default     = 900
}

variable "token_max_ttl" {
  description = "Maximum TTL of minted tokens, in seconds."
  type        = number
  default     = 3600
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to authenticate via OIDC."
  type        = string
  default     = "kmridha92/tfe-vault-token-service"
}
