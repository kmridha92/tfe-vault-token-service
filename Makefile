export VAULT_ADDR ?= http://127.0.0.1:8200
export VAULT_TOKEN ?= root

.PHONY: up down init apply plan demo-approle fmt validate

up:
	docker compose up -d

down:
	docker compose down

init:
	terraform -chdir=terraform init

plan: init
	terraform -chdir=terraform plan

# Requires TF_VAR_tfe_admin_token and TF_VAR_tfe_user_id in the environment
apply: init
	terraform -chdir=terraform apply

fmt:
	terraform -chdir=terraform fmt -recursive

validate: init
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform validate

demo-approle:
	./scripts/demo-approle.sh
