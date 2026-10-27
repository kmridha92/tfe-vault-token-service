# --- TFE secrets engine -----------------------------------------------------

resource "vault_terraform_cloud_secret_backend" "tfe" {
  backend     = "terraform"
  address     = var.tfe_address
  token       = var.tfe_admin_token
  description = "Mints short-lived Terraform tokens"

  default_lease_ttl_seconds = var.token_ttl
  max_lease_ttl_seconds     = var.token_max_ttl
}

resource "vault_terraform_cloud_secret_role" "ci" {
  backend = vault_terraform_cloud_secret_backend.tfe.backend
  name    = "ci"
  user_id = var.tfe_user_id
  ttl     = var.token_ttl
  max_ttl = var.token_max_ttl
}

# --- Policy: read-only access to mint tokens --------------------------------

resource "vault_policy" "tfe_token_reader" {
  name = "tfe-token-reader"

  policy = <<-EOT
    path "${vault_terraform_cloud_secret_backend.tfe.backend}/creds/${vault_terraform_cloud_secret_role.ci.name}" {
      capabilities = ["read"]
    }
  EOT
}

# --- Auth: AppRole (machines / local testing) -------------------------------

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "ci" {
  backend            = vault_auth_backend.approle.path
  role_name          = "ci"
  token_policies     = [vault_policy.tfe_token_reader.name]
  token_ttl          = 300
  token_max_ttl      = 600
  secret_id_ttl      = 3600
  secret_id_num_uses = 10
}

# --- Auth: JWT/OIDC (GitHub Actions) ----------------------------------------

resource "vault_jwt_auth_backend" "github" {
  path               = "jwt-github"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_jwt_auth_backend_role" "github_ci" {
  backend         = vault_jwt_auth_backend.github.path
  role_name       = "github-ci"
  role_type       = "jwt"
  user_claim      = "repository"
  bound_audiences = ["vault"]
  bound_claims = {
    repository = var.github_repository
  }
  token_policies = [vault_policy.tfe_token_reader.name]
  token_ttl      = 300
}
