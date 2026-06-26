# ============================================================
# DFC Makefile — Single entry point for all platform operations
# ============================================================
.PHONY: help infra stop smoke load deploy logs fmt analyze clean orchestrator start-pm2

SHELL := /bin/bash

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ---------- Infrastructure ----------
infra: ## Start full stack (Docker Compose + health checks)
	bash scripts/run_all.sh

orchestrator: ## Run deterministic task orchestrator
	node tools/task-orchestrator.js

start-pm2: ## Start persistent local services with PM2
	pm2 resurrect || pm2 start ecosystem.config.js

stop: ## Stop all services and orphan containers
	bash scripts/stop_all.sh

# ---------- Quality ----------
fmt: ## Format Dart + JS
	dart format .
	npx prettier --write "serverless/**/*.js" "server/**/*.js" || true

analyze: ## Run Flutter analyzer
	flutter analyze

lint: ## Run linting across the project
	npm run lint || true
	flutter analyze || true

# ---------- Testing ----------
smoke: ## Run strict smoke test suite
	bash ci/smoke_clip_publish_strict.sh

load-checkout: ## k6 load test — checkout & token flow
	k6 run load/checkout_and_token.js

load-playback: ## k6 load test — playback startup
	k6 run load/playback_startup.js

load: load-checkout load-playback ## Run all k6 load tests

test: ## Run Flutter unit tests
	flutter test

# ---------- Deploy ----------
deploy-serverless: ## Deploy serverless functions to AWS
	cd serverless && npx serverless deploy --stage $${STAGE:-staging}

deploy-firebase: ## Deploy Firebase Functions
	cd functions && npm ci && npx firebase deploy --only functions

deploy: deploy-serverless deploy-firebase ## Deploy everything

# ---------- Utilities ----------
logs: ## Collect event logs from all services
	bash scripts/collect_event_logs.sh

emulators: ## Start Firebase emulators with saved data
	pwsh -ExecutionPolicy Bypass -File scripts/start_emulators.ps1 -KillExisting -Import -Export

serverless-offline: ## Start serverless-offline for local dev
	cd serverless && npx serverless offline start --httpPort 3001

clean: ## Flutter clean + remove build artifacts
	flutter clean
	flutter pub get
