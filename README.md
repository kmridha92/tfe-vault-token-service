# TFE Vault Token Service

Short-lived Terraform tokens minted on demand by HashiCorp Vault's Terraform Cloud/Enterprise secrets engine, so CI pipelines never hold long-lived tokens. Vault is configured entirely as code with Terraform.

## Architecture

```
GitHub Actions (OIDC JWT) ─┐
                           ├─> Vault auth (jwt-github / approle)
AppRole (local/machines) ──┘        │ policy: tfe-token-reader
                                    ▼
                         terraform/creds/ci  ──>  HCP Terraform user token (TTL 15m, max 1h)
```

- Secrets engine `terraform`, role `ci` (user-token based, works on HCP Terraform free tier)
- Policy `tfe-token-reader`: read on `terraform/creds/ci` only
- Auth: AppRole `ci` and GitHub Actions JWT role `github-ci` bound to repository `kmridha92/tfe-vault-token-service`

## Quickstart

Prereqs: Docker, Vault CLI, Terraform.

```sh
make up                                  # Vault 2.2 in dev mode on :8200
export TF_VAR_tfe_admin_token=...        # HCP Terraform token (never commit)
export TF_VAR_tfe_user_id=user-...
make apply
make demo-approle                        # AppRole login -> mint short-lived token
make down
```

`make validate` runs fmt and validate without needing credentials.

## CI

- `ci.yml`: fmt, validate, Checkov
- `oidc-demo.yml`: manual workflow showing JWT/OIDC login (needs a publicly reachable Vault and `VAULT_ADDR` repo variable)

## Security notes

- Dev mode Vault (root token `root`, in-memory, no TLS) is for local use only.
- Terraform state contains the admin token; keep state local/ignored or use a remote encrypted backend.
- The GitHub JWT login can only be fully exercised from a real Actions run.

## Status
Config validated; end-to-end test against HCP Terraform pending credentials.
