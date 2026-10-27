#!/usr/bin/env bash
# Usage: demo-approle.sh <team>
# Logs in with the team's AppRole and reads its short-lived TFE token (not printed in full).
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
TEAM="${1:?usage: $0 <team>}"
ADMIN_TOKEN="${VAULT_TOKEN:-root}"

role_id=$(VAULT_TOKEN="$ADMIN_TOKEN" vault read -field=role_id auth/approle/role/$TEAM/role-id)
secret_id=$(VAULT_TOKEN="$ADMIN_TOKEN" vault write -f -field=secret_id auth/approle/role/$TEAM/secret-id)

client_token=$(vault write -field=token auth/approle/login role_id="$role_id" secret_id="$secret_id")

echo "Logged in via AppRole. Requesting TFE token..."
VAULT_TOKEN="$client_token" vault read -format=json terraform-$TEAM/creds/$TEAM \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print("lease_id:", d["lease_id"]); print("lease_duration:", d["lease_duration"]); print("token: ", d["data"]["token"][:6] + "...")'
