output "token_read_path" {
  description = "Vault path that returns a short-lived TFE token."
  value       = "${vault_terraform_cloud_secret_backend.tfe.backend}/creds/${vault_terraform_cloud_secret_role.ci.name}"
}

output "approle_role_id" {
  description = "AppRole role ID for the ci role."
  value       = vault_approle_auth_backend_role.ci.role_id
}
