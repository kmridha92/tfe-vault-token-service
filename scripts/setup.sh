#!/usr/bin/env bash
# Sets up local Vault, the TFE secrets engine and one role per team.
# Usage: scripts/setup.sh [env-file]
#   env-file (optional) is sourced first and may export TF_VAR_tfe_admin_token and TF_VAR_tfe_user_id.
set -euo pipefail

cd "$(dirname "$0")/.."

[ -n "${1:-}" ] && source "$1"

for cmd in docker terraform vault; do
  command -v "$cmd" >/dev/null || { echo "missing prerequisite: $cmd" >&2; exit 1; }
done
: "${TF_VAR_tfe_admin_token:?export TF_VAR_tfe_admin_token (HCP Terraform user token)}"
: "${TF_VAR_tfe_user_id:?export TF_VAR_tfe_user_id (user-xxxx)}"

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-root}"

echo "==> Starting Vault"
docker compose up -d

echo "==> Waiting for Vault to be ready"
for _ in $(seq 1 30); do
  curl -fs "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1 && break
  sleep 1
done
curl -fs "$VAULT_ADDR/v1/sys/health" >/dev/null || { echo "Vault did not become ready" >&2; exit 1; }

echo "==> Applying Terraform (engine, teams, policies, auth)"
terraform -chdir=terraform init -input=false
terraform -chdir=terraform apply -auto-approve -input=false

echo
echo "Done. UI: $VAULT_ADDR/ui (token: $VAULT_TOKEN)"
echo "Try:   make demo-approle TEAM=team1"
