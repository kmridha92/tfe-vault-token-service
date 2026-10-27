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
  description = "HCP Terraform user ID (user-xxxx) owning tfe_admin_token. Used by roles of teams without a team_ids entry."
  type        = string
}

variable "teams" {
  description = "Teams. Each gets a one-to-one Vault role, policy, AppRole and GitHub OIDC role."
  type        = set(string)
  default     = ["team1", "team2", "team3"]
}

variable "team_ids" {
  description = "Optional HCP Terraform team IDs (team-xxxx), keyed by team name. Teams listed here get team-token roles (paid plan); others get user-token roles for tfe_user_id."
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
