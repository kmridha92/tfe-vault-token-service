# --- HCP Terraform teams (one per entry in var.teams) -----------------------

resource "tfe_team" "this" {
  for_each     = var.teams
  organization = var.tfe_organization
  name         = each.key
}

# --- TFE secrets engine -----------------------------------------------------

resource "vault_terraform_cloud_secret_backend" "tfe" {
  backend     = "terraform"
  address     = var.tfe_address
  token       = var.tfe_admin_token
  description = "Mints short-lived Terraform tokens"

  default_lease_ttl_seconds = var.token_ttl
  max_lease_ttl_seconds     = var.token_max_ttl
}

# One role per team, mapped 1:1 by name
resource "vault_terraform_cloud_secret_role" "team" {
  for_each = var.teams
  backend  = vault_terraform_cloud_secret_backend.tfe.backend
  name     = each.key
  team_id  = tfe_team.this[each.key].id
  ttl      = var.token_ttl
  max_ttl  = var.token_max_ttl
}

# --- Policy per team: read only its own role --------------------------------

resource "vault_policy" "team" {
  for_each = var.teams
  name     = "tfe-token-${each.key}"

  policy = <<-EOT
    path "${vault_terraform_cloud_secret_backend.tfe.backend}/creds/${vault_terraform_cloud_secret_role.team[each.key].name}" {
      capabilities = ["read"]
    }
  EOT
}

# --- Auth: AppRole per team (machines / local testing) ----------------------

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "team" {
  for_each           = var.teams
  backend            = vault_auth_backend.approle.path
  role_name          = each.key
  token_policies     = [vault_policy.team[each.key].name]
  token_ttl          = 300
  token_max_ttl      = 600
  secret_id_ttl      = 3600
  secret_id_num_uses = 10
}

# --- Auth: JWT/OIDC per team (GitHub Actions) -------------------------------
# A workflow must run in a GitHub environment named after the team, so one
# team's pipeline cannot assume another team's role.

resource "vault_jwt_auth_backend" "github" {
  path               = "jwt-github"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_jwt_auth_backend_role" "team" {
  for_each        = var.teams
  backend         = vault_jwt_auth_backend.github.path
  role_name       = each.key
  role_type       = "jwt"
  user_claim      = "repository"
  bound_audiences = ["vault"]
  bound_claims = {
    repository  = coalesce(each.value.github_repository, var.github_repository)
    environment = each.key
  }
  token_policies = [vault_policy.team[each.key].name]
  token_ttl      = 300
}
