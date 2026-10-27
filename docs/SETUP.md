# Setup guide

Sets up a local Vault (Docker), the Terraform Cloud/Enterprise secrets engine, and one role, policy, AppRole and GitHub OIDC role per team.

## Prerequisites

- Docker (running), Terraform >= 1.5, Vault CLI
- An HCP Terraform user token (Account Settings → Tokens) and your user ID (`user-...`, shown at `https://app.terraform.io/api/v2/account/details`)

## 1. Provide credentials

Keep them outside the repo, for example in `~/.secrets/tfe.env` (`chmod 600`):

```sh
export TF_VAR_tfe_admin_token="..."
export TF_VAR_tfe_user_id="user-..."
```

## 2. Run setup

```sh
scripts/setup.sh ~/.secrets/tfe.env
```

This starts Vault 2.2 (dev mode, root token `root`), waits until it is healthy, then runs `terraform init` and `apply`.

Manual equivalent:

```sh
source ~/.secrets/tfe.env
make up
make apply
```

## 3. What gets created

| Object | Name |
|---|---|
| Secrets engine | `terraform` |
| Role per team | `team1`, `team2`, `team3` |
| Policy per team | `tfe-token-<team>` (read `terraform/creds/<team>` only) |
| AppRole per team | `<team>` |
| JWT auth `jwt-github` role per team | `<team>` (repo + GitHub environment `<team>`) |

## 4. Verify

```sh
make demo-approle TEAM=team1     # AppRole login, mints a 15-minute token
```

Vault UI: http://127.0.0.1:8200/ui, sign in with the token `root`.

## Customising teams

Edit `teams` (a set of names) in `terraform/terraform.tfvars` (git-ignored; see `terraform.tfvars.example`):

```hcl
teams = ["platform", "payments"]
```

Optional per-team overrides:

- `team_ids = { platform = "team-xxxx" }` uses real HCP Terraform team tokens (paid plan) instead of your user token.
- `team_github_repositories = { payments = "org/payments" }` sets the repo allowed via OIDC.

Re-run `make apply`.

## Tear down

```sh
make down      # dev-mode Vault is in memory, so all config is lost
```

Revoke any outstanding tokens with `vault lease revoke -prefix terraform/creds`. Tokens also expire on their own after the TTL.

## Troubleshooting

- `missing entitlements to create teams`: real HCP Terraform teams need a paid plan; this project does not create them.
- Vault CLI version warning: harmless when the CLI is older than the server.
- Docker not running: start Docker Desktop, then re-run.
