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

variable "tfe_user_id" {
  description = "HCP Terraform user ID (user-xxxx) that minted tokens belong to. User tokens work on the free tier; team tokens need a paid plan."
  type        = string
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
