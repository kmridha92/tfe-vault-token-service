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
  description = "HCP Terraform user token Vault uses to mint tokens (default for all teams)."
  type        = string
  sensitive   = true
}

variable "tfe_user_id" {
  description = "HCP Terraform user ID (user-xxxx) owning tfe_admin_token. Default for every team."
  type        = string
}

variable "teams" {
  description = "Simulated teams (free tier). Each gets a one-to-one Vault mount, role, policy, AppRole and GitHub OIDC role."
  type        = set(string)
  default     = ["team1", "team2", "team3"]
}

variable "team_tokens" {
  description = "Per-team HCP Terraform user token, keyed by team. Falls back to tfe_admin_token. Use separate accounts for real isolation."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "team_user_ids" {
  description = "Per-team HCP Terraform user ID, keyed by team. Falls back to tfe_user_id."
  type        = map(string)
  default     = {}
}

variable "team_github_repositories" {
  description = "Per-team GitHub repository (owner/name) allowed via OIDC. Falls back to github_repository."
  type        = map(string)
  default     = {}
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
