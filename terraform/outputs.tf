output "token_read_paths" {
  description = "Vault path per team that returns a short-lived TFE user token."
  value = {
    for k, r in vault_terraform_cloud_secret_role.team :
    k => "${vault_terraform_cloud_secret_backend.team[k].backend}/creds/${r.name}"
  }
}

output "approle_role_ids" {
  description = "AppRole role ID per team."
  value       = { for k, r in vault_approle_auth_backend_role.team : k => r.role_id }
}
