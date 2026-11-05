# Front door for the repo: `make` (or `make help`) lists everything.
#
#   make plan        -> show what would change in envs/dev (changes nothing)
#   make apply       -> plan, confirm, apply exactly that plan
#   make destroy     -> plan destroy, confirm, apply exactly that plan
#   make ci          -> every offline check CI runs (no Azure access needed)

ENV ?= dev
TF  := scripts/tf.sh
ROOTS := bootstrap envs/dev

.DEFAULT_GOAL := help
.PHONY: help plan apply destroy output fmt check lint security test ci

help: ## Show this help
	@echo "Usage: make <target> [ENV=dev]   (default ENV=$(ENV))"
	@echo
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

plan: ## Show what would change - changes nothing
	@$(TF) $(ENV) plan

apply: ## Plan, confirm, apply exactly that plan
	@$(TF) $(ENV) apply

destroy: ## Plan destroy, confirm, apply exactly that plan
	@$(TF) $(ENV) destroy

output: ## Show the environment's outputs
	@$(TF) $(ENV) output

fmt: ## Format all Terraform files
	terraform fmt -recursive

check: ## fmt check + validate every root (offline, no Azure access)
	terraform fmt -check -recursive
	@for d in $(ROOTS); do \
	  echo "== $$d"; \
	  terraform -chdir=$$d init -backend=false -input=false >/dev/null && \
	  terraform -chdir=$$d validate || exit 1; \
	done

lint: ## tflint, incl. azurerm rules, on every root and module
	tflint --init
	tflint --recursive

security: ## checkov security + leaked-secrets scan
	checkov --config-file .checkov.yaml

test: ## Unit tests for every module (mock providers - offline, free)
	@for m in modules/*/; do \
	  echo "== $$m"; \
	  terraform -chdir=$$m init -backend=false -input=false >/dev/null && \
	  terraform -chdir=$$m test || exit 1; \
	done

ci: check lint security test ## Everything CI runs, in order
