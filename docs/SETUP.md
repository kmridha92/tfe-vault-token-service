# Setup guide

Sets up a local Vault (Docker), the Terraform Cloud/Enterprise secrets engine, and one role, policy, AppRole and GitHub OIDC role per team.

## Prerequisites

- Docker (running), Terraform >= 1.5, Vault CLI
- An HCP Terraform user token (Account Settings → Tokens) and your user ID (`user-...`, shown at `https://app.terraform.io/api/v2/account/details`)

## 1. Provide credentials

Keep them outside the repo, for example in `~/.secrets/secrets.env` (`chmod 600`):

```sh
export TF_VAR_tfe_admin_token="..."
export TF_VAR_tfe_user_id="user-..."
```

## 2. Run setup

```sh
scripts/setup.sh ~/.secrets/secrets.env
```

This starts Vault 2.2 (dev mode, root token `root`), waits until it is healthy, then runs `terraform init` and `apply`.

Manual equivalent:

```sh
source ~/.secrets/secrets.env
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

## 5. Get a token (manual)

```sh
export VAULT_ADDR=http://127.0.0.1:8200

# 1. Admin: fetch the team's AppRole credentials
ROLE_ID=$(VAULT_TOKEN=root vault read -field=role_id auth/approle/role/team1/role-id)
SECRET_ID=$(VAULT_TOKEN=root vault write -f -field=secret_id auth/approle/role/team1/secret-id)

# 2. Team: log in (the Vault token lives 5 minutes)
export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")

# 3. Team: mint a short-lived HCP Terraform token
vault read terraform/creds/team1
vault read -field=token terraform/creds/team1      # token only

# Use it with Terraform CLI
export TF_TOKEN_app_terraform_io=$(vault read -field=token terraform/creds/team1)
```

A team can only read its own path; `terraform/creds/team2` returns `permission denied`.

From GitHub Actions the login uses OIDC instead of AppRole; see `.github/workflows/oidc-demo.yml`.

## 6. Rotate and revoke

Minted tokens are leases (TTL 15 minutes, max 1 hour) and expire on their own.

```sh
# Renew a lease (up to the max TTL)
vault lease renew -increment=1200 terraform/creds/team1/<lease-id>

# Revoke one token early
vault lease revoke terraform/creds/team1/<lease-id>

# Revoke every outstanding token for a team, or for all teams
vault lease revoke -prefix terraform/creds/team1
vault lease revoke -prefix terraform/creds
```

Revoked leases also delete the token in HCP Terraform.

**Rotate a team's AppRole secret ID** (TTL 1 hour, 10 uses by default):

```sh
export VAULT_TOKEN=root
vault list auth/approle/role/team1/secret-id            # accessors of existing secret IDs
vault write -f auth/approle/role/team1/secret-id        # issue a new one
vault write auth/approle/role/team1/secret-id-accessor/destroy secret_id_accessor=<accessor>
```

**Rotate the admin token Vault uses to mint tokens** (`tfe_admin_token`):

1. Create a new token in HCP Terraform (Account Settings → Tokens).
2. Update `TF_VAR_tfe_admin_token` in `~/.secrets/secrets.env`, then `source` it.
3. Run `make apply` (Terraform updates `terraform/config`).
4. Delete the old token in HCP Terraform.

Tokens already minted keep working until they expire or are revoked. Revoke them first if you want an immediate cut-off.

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
