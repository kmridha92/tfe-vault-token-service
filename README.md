# TFE Vault Token Service

Short-lived Terraform tokens minted on demand by HashiCorp Vault's Terraform Cloud/Enterprise secrets engine, so CI pipelines never hold long-lived tokens. Vault is configured entirely as code with Terraform.

## Architecture

```
GitHub Actions (OIDC, environment=<team>) ─┐
                                           ├─> Vault auth role <team> ─> policy tfe-token-<team>
AppRole <team> (local/machines) ───────────┘            │
                                                        ▼
                    terraform/creds/<team> ──> HCP Terraform token (TTL 15m, max 1h)
```

One `terraform` secrets engine with one role per entry in `var.teams` (default `team1`, `team2`, `team3`), mapped one to one:

| Vault object | Name |
|---|---|
| Role on the `terraform` engine | `<team>` |
| Policy | `tfe-token-<team>`: read on `terraform/creds/<team>` only |
| AppRole and JWT role | `<team>` (JWT bound to the repo and GitHub environment `<team>`) |

On the free tier, roles use `user_id`, so all teams mint tokens for your single account (they differ in Vault identity, policy and lease, not in HCP Terraform identity). On a paid plan, set `team_ids = { team1 = "team-xxxx" }` to switch a team's role to real HCP Terraform team tokens.

A team's identity can only read its own path; reading another team's path is denied.

## Quickstart

Full guide: [docs/SETUP.md](docs/SETUP.md). One-shot: `scripts/setup.sh ~/.secrets/tfe.env`.

Prereqs: Docker, Vault CLI, Terraform.

```sh
make up                                    # Vault 2.2 in dev mode on :8200
export TF_VAR_tfe_admin_token=...          # HCP Terraform user token (never commit)
export TF_VAR_tfe_user_id=user-...
make apply
make demo-approle TEAM=team1               # AppRole login -> mint team1 token
make down
```

Add a team by adding it to `teams` and applying.

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
