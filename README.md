# TFE Vault Token Service

Short-lived Terraform tokens minted on demand by HashiCorp Vault's Terraform Cloud/Enterprise secrets engine, so CI pipelines never hold long-lived tokens. Vault is configured entirely as code with Terraform.

## Architecture

```
GitHub Actions (OIDC, environment=<team>) ─┐
                                           ├─> Vault auth role <team> ─> policy tfe-token-<team>
AppRole <team> (local/machines) ───────────┘            │
                                                        ▼
                         terraform/creds/<team> ──> HCP Terraform team token (TTL 15m, max 1h)
```

Each entry in `var.teams` (default `team1`, `team2`, `team3`) maps one to one:

| HCP Terraform | Vault |
|---|---|
| Team `<team>` (created by the `tfe` provider) | TFE secrets engine role `<team>` (`team_id`) |
| | Policy `tfe-token-<team>`: read on `terraform/creds/<team>` only |
| | AppRole `<team>` and JWT role `<team>` (bound to the repo and GitHub environment `<team>`) |

Teams are isolated: a team's identity can only mint its own team token. Team tokens need a paid HCP Terraform plan (or trial).

## Quickstart

Prereqs: Docker, Vault CLI, Terraform.

```sh
make up                                    # Vault 2.2 in dev mode on :8200
export TF_VAR_tfe_admin_token=...          # org owner token (never commit)
export TF_VAR_tfe_organization=my-org
make apply                                 # creates teams + Vault config
make demo-approle TEAM=team1               # AppRole login -> mint team1 token
make down
```

Add a team by adding a key to `teams` and applying.

`make validate` runs fmt and validate without needing credentials.

## CI

- `ci.yml`: fmt, validate, Checkov
- `oidc-demo.yml`: manual workflow (pick a team; runs in the matching GitHub environment) showing JWT/OIDC login (needs a publicly reachable Vault and `VAULT_ADDR` repo variable)

## Security notes

- Dev mode Vault (root token `root`, in-memory, no TLS) is for local use only.
- Terraform state contains the admin token; keep state local/ignored or use a remote encrypted backend.
- The GitHub JWT login can only be fully exercised from a real Actions run.

## Status
Applied to local Vault and verified end to end: AppRole login mints a 15-minute HCP Terraform user token. GitHub OIDC login is untested until run from Actions against a reachable Vault.
