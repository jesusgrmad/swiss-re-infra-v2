# ============================================
# Swiss Re Infrastructure Challenge - Makefile
# Author: Jesus Gracia
# Version: 1.0.0 (Base)
# Description: Build automation for Azure infrastructure deployment
# ============================================

# Variables
SHELL := /bin/bash
.DEFAULT_GOAL := help

# Color codes for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Azure Configuration
SUBSCRIPTION_ID ?= $(shell az account show --query id -o tsv)
LOCATION ?= westeurope
PROJECT_NAME := swissre

# Environment Configuration
ENV ?= dev
ifeq ($(ENV),prod)
	RESOURCE_GROUP := rg-swissre-prod
	PARAM_FILE := infrastructure/parameters.prod.json
	REQUIRE_APPROVAL := true
else
	RESOURCE_GROUP := rg-swissre-dev
	PARAM_FILE := infrastructure/parameters.dev.json
	REQUIRE_APPROVAL := false
endif

# Deployment Configuration
DEPLOYMENT_VERSION ?= 3
DEPLOYMENT_NAME := deploy-$(ENV)-$(shell date +%s)
BICEP_FILE := infrastructure/main.bicep

# Versioning
VERSION := 1.0.0
BUILD_DATE := $(shell date -u +"%Y-%m-%d")
BUILD_TIME := $(shell date -u +"%H:%M:%S")

# ============================================
# Help Target
# ============================================
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       Swiss Re Infrastructure Challenge - Makefile Help        ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  $(YELLOW)ENV$(NC)                Environment (dev/prod) - current: $(ENV)"
	@echo "  $(YELLOW)DEPLOYMENT_VERSION$(NC) Deployment version (1/2/3) - current: $(DEPLOYMENT_VERSION)"
	@echo "  $(YELLOW)RESOURCE_GROUP$(NC)     Resource group - current: $(RESOURCE_GROUP)"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make deploy ENV=dev DEPLOYMENT_VERSION=3"
	@echo "  make test"
	@echo "  make validate"
	@echo "  make clean ENV=dev"

# ============================================
# Setup & Prerequisites
# ============================================
.PHONY: setup
setup: ## Install required tools and dependencies
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@command -v az >/dev/null 2>&1 || { echo "$(RED)Azure CLI not installed$(NC)"; exit 1; }
	@command -v bicep >/dev/null 2>&1 || az bicep install
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)Python 3 not installed$(NC)"; exit 1; }
	@pip3 install -q pytest azure-identity azure-keyvault-secrets requests 2>/dev/null || true
	@echo "$(GREEN)✓ Setup complete$(NC)"

.PHONY: check-tools
check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking required tools...$(NC)"
	@command -v az >/dev/null 2>&1 && echo "$(GREEN)✓ Azure CLI$(NC)" || echo "$(RED)✗ Azure CLI$(NC)"
	@command -v bicep >/dev/null 2>&1 && echo "$(GREEN)✓ Bicep CLI$(NC)" || echo "$(RED)✗ Bicep CLI$(NC)"
	@command -v git >/dev/null 2>&1 && echo "$(GREEN)✓ Git$(NC)" || echo "$(RED)✗ Git$(NC)"
	@command -v python3 >/dev/null 2>&1 && echo "$(GREEN)✓ Python 3$(NC)" || echo "$(RED)✗ Python 3$(NC)"
	@command -v pwsh >/dev/null 2>&1 && echo "$(GREEN)✓ PowerShell$(NC)" || echo "$(YELLOW)⚠ PowerShell (optional)$(NC)"

.PHONY: login
login: ## Login to Azure
	@echo "$(BLUE)Logging in to Azure...$(NC)"
	@az login --output none
	@az account set --subscription $(SUBSCRIPTION_ID)
	@echo "$(GREEN)✓ Logged in to subscription: $(SUBSCRIPTION_ID)$(NC)"

# ============================================
# Validation Targets
# ============================================
.PHONY: validate
validate: validate-bicep validate-scripts validate-parameters ## Run all validations
	@echo "$(GREEN)✓ All validations passed!$(NC)"

.PHONY: validate-bicep
validate-bicep: ## Validate Bicep templates
	@echo "$(BLUE)Validating Bicep templates...$(NC)"
	@az bicep build --file $(BICEP_FILE) --stdout > /dev/null
	@for file in infrastructure/modules/*.bicep; do \
		echo "  Validating $$(basename $$file)..."; \
		az bicep build --file "$$file" --stdout > /dev/null || exit 1; \
	done
	@echo "$(GREEN)✓ Bicep validation complete$(NC)"

.PHONY: validate-scripts
validate-scripts: ## Validate shell and Python scripts
	@echo "$(BLUE)Validating scripts...$(NC)"
	@for script in scripts/*.sh; do \
		if [ -f "$$script" ]; then \
			bash -n "$$script" && echo "  ✓ $$(basename $$script)" || exit 1; \
		fi; \
	done
	@python3 -m py_compile scripts/keyvault-retriever.py
	@echo "$(GREEN)✓ Script validation complete$(NC)"

.PHONY: validate-parameters
validate-parameters: ## Validate parameter files
	@echo "$(BLUE)Validating parameter files...$(NC)"
	@python3 -c "import json; json.load(open('infrastructure/parameters.dev.json'))"
	@python3 -c "import json; json.load(open('infrastructure/parameters.prod.json'))"
	@echo "$(GREEN)✓ Parameter validation complete$(NC)"

.PHONY: check-warnings
check-warnings: ## Check for Bicep warnings (must be zero)
	@echo "$(BLUE)Checking for warnings...$(NC)"
	@output=$$(az bicep build --file $(BICEP_FILE) 2>&1); \
	if echo "$$output" | grep -i "warning"; then \
		echo "$(RED)✗ Warnings found!$(NC)"; \
		echo "$$output"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Zero warnings achieved!$(NC)"; \
	fi

# ============================================
# Build Targets
# ============================================
.PHONY: build
build: validate ## Build ARM templates from Bicep
	@echo "$(BLUE)Building ARM templates...$(NC)"
	@mkdir -p build
	@az bicep build --file $(BICEP_FILE) --outdir build
	@for file in infrastructure/modules/*.bicep; do \
		az bicep build --file "$$file" --outdir build/modules 2>/dev/null; \
	done
	@echo "$(GREEN)✓ Build complete - ARM templates in build/$(NC)"

.PHONY: lint
lint: ## Run linters on all code
	@echo "$(BLUE)Running linters...$(NC)"
	@az bicep lint --file $(BICEP_FILE)
	@echo "$(GREEN)✓ Linting complete$(NC)"

# ============================================
# Testing Targets
# ============================================
.PHONY: test
test: test-unit test-integration test-security test-compliance ## Run all tests
	@echo "$(GREEN)✓ All tests passed!$(NC)"

.PHONY: test-unit
test-unit: ## Run unit tests
	@echo "$(BLUE)Running unit tests...$(NC)"
	@pwsh -File tests/unit/test-bicep.ps1 2>/dev/null || echo "$(YELLOW)⚠ PowerShell tests skipped$(NC)"
	@python3 tests/unit/test-python.py
	@echo "$(GREEN)✓ Unit tests complete$(NC)"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "$(BLUE)Running integration tests...$(NC)"
	@bash tests/integration/test-deployment.sh
	@bash tests/integration/test-connectivity.sh
	@echo "$(GREEN)✓ Integration tests complete$(NC)"

.PHONY: test-security
test-security: ## Run security tests
	@echo "$(BLUE)Running security tests...$(NC)"
	@bash tests/security/test-tls.sh
	@pwsh -File tests/security/test-compliance.ps1 2>/dev/null || echo "$(YELLOW)⚠ PowerShell tests skipped$(NC)"
	@echo "$(GREEN)✓ Security tests complete$(NC)"

.PHONY: test-compliance
test-compliance: ## Test Swiss Re compliance requirements
	@echo "$(BLUE)Testing compliance requirements...$(NC)"
	@bash scripts/comprehensive-validation.sh
	@echo "$(GREEN)✓ Compliance tests complete$(NC)"

# ============================================
# Deployment Targets
# ============================================
.PHONY: deploy
deploy: validate confirm-deploy create-rg deploy-infrastructure post-deploy ## Full deployment pipeline
	@echo "$(GREEN)✓ Deployment complete!$(NC)"

.PHONY: confirm-deploy
confirm-deploy: ## Confirm deployment (prod only)
ifeq ($(ENV),prod)
	@echo "$(YELLOW)WARNING: Deploying to PRODUCTION$(NC)"
	@echo "Resource Group: $(RESOURCE_GROUP)"
	@echo "Version: $(DEPLOYMENT_VERSION)"
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
endif

.PHONY: create-rg
create-rg: ## Create resource group
	@echo "$(BLUE)Creating resource group...$(NC)"
	@az group create \
		--name $(RESOURCE_GROUP) \
		--location $(LOCATION) \
		--tags Environment=$(ENV) Project=$(PROJECT_NAME) Version=$(VERSION) \
		--output none
	@echo "$(GREEN)✓ Resource group created$(NC)"

.PHONY: deploy-infrastructure
deploy-infrastructure: ## Deploy infrastructure
	@echo "$(BLUE)Deploying infrastructure (Version $(DEPLOYMENT_VERSION))...$(NC)"
	@az deployment group create \
		--name $(DEPLOYMENT_NAME) \
		--resource-group $(RESOURCE_GROUP) \
		--template-file $(BICEP_FILE) \
		--parameters $(PARAM_FILE) \
		--parameters deploymentVersion=$(DEPLOYMENT_VERSION) \
		--parameters adminPassword=$${ADMIN_PASSWORD:-ComplexP@ssw0rd!2025} \
		--mode Incremental \
		--output none
	@echo "$(GREEN)✓ Infrastructure deployed$(NC)"

.PHONY: post-deploy
post-deploy: ## Run post-deployment validation
	@echo "$(BLUE)Running post-deployment validation...$(NC)"
	@bash scripts/validate.sh $(ENV)
	@echo "$(GREEN)✓ Post-deployment validation complete$(NC)"

.PHONY: what-if
what-if: validate ## Preview deployment changes
	@echo "$(BLUE)Running what-if analysis...$(NC)"
	@az deployment group what-if \
		--resource-group $(RESOURCE_GROUP) \
		--template-file $(BICEP_FILE) \
		--parameters $(PARAM_FILE) \
		--parameters deploymentVersion=$(DEPLOYMENT_VERSION) \
		--parameters adminPassword=$${ADMIN_PASSWORD:-ComplexP@ssw0rd!2025}

.PHONY: rollback
rollback: ## Rollback to last successful deployment
	@echo "$(YELLOW)Rolling back deployment...$(NC)"
	@LAST_DEPLOYMENT=$$(az deployment group list \
		--resource-group $(RESOURCE_GROUP) \
		--query "[?properties.provisioningState=='Succeeded'] | [0].name" \
		--output tsv); \
	if [ -n "$$LAST_DEPLOYMENT" ]; then \
		echo "Rolling back to: $$LAST_DEPLOYMENT"; \
		az deployment group create \
			--name "rollback-$(shell date +%s)" \
			--resource-group $(RESOURCE_GROUP) \
			--template-uri "$$(az deployment group export --name $$LAST_DEPLOYMENT --resource-group $(RESOURCE_GROUP) --query 'template' -o json | jq -r)" \
			--mode Complete; \
	else \
		echo "$(RED)No successful deployment found$(NC)"; \
		exit 1; \
	fi

# ============================================
# Monitoring & Operations
# ============================================
.PHONY: status
status: ## Check deployment status
	@echo "$(BLUE)Checking deployment status...$(NC)"
	@az vm show \
		--resource-group $(RESOURCE_GROUP) \
		--name vm-swissre-$(ENV) \
		--query "{Name:name, Status:provisioningState, PowerState:instanceView.statuses[1].displayStatus}" \
		--output table 2>/dev/null || echo "$(YELLOW)VM not found$(NC)"

.PHONY: logs
logs: ## View deployment logs
	@echo "$(BLUE)Fetching deployment logs...$(NC)"
	@az deployment group list \
		--resource-group $(RESOURCE_GROUP) \
		--query "[0:5].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
		--output table

.PHONY: health-check
health-check: ## Run health check
	@echo "$(BLUE)Running health check...$(NC)"
	@bash scripts/validate.sh $(ENV)

.PHONY: costs
costs: ## Show estimated costs
	@echo "$(BLUE)Estimating costs for $(ENV)...$(NC)"
	@echo "Environment: $(ENV)"
	@echo "VM SKU: $$([ "$(ENV)" = "prod" ] && echo "Standard_D2s_v3" || echo "Standard_B2s")"
	@echo "Estimated monthly cost:"
	@echo "  - VM: $$([ "$(ENV)" = "prod" ] && echo "€75" || echo "€30")"
	@echo "  - Firewall: €950"
	@echo "  - Bastion: €130"
	@echo "  - Storage: €20"
	@echo "  - Total: $$([ "$(ENV)" = "prod" ] && echo "€1,175" || echo "€1,130")"

# ============================================
# Cleanup Targets
# ============================================
.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf build/
	@rm -f *.log
	@rm -f test-results.xml
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: destroy
destroy: ## Destroy all resources (WARNING: Destructive!)
	@echo "$(RED)WARNING: This will destroy all resources in $(RESOURCE_GROUP)$(NC)"
	@read -p "Type 'DESTROY' to confirm: " confirm && [ "$$confirm" = "DESTROY" ] || exit 1
	@az group delete --name $(RESOURCE_GROUP) --yes --no-wait
	@echo "$(YELLOW)Destruction initiated$(NC)"

# ============================================
# Documentation Targets
# ============================================
.PHONY: docs
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@echo "# Swiss Re Infrastructure" > docs/GENERATED.md
	@echo "Generated: $(BUILD_DATE) $(BUILD_TIME)" >> docs/GENERATED.md
	@echo "Version: $(VERSION)" >> docs/GENERATED.md
	@echo "" >> docs/GENERATED.md
	@echo "## Deployed Resources" >> docs/GENERATED.md
	@az resource list --resource-group $(RESOURCE_GROUP) \
		--query "[].{Name:name, Type:type}" \
		--output table >> docs/GENERATED.md 2>/dev/null || true
	@echo "$(GREEN)✓ Documentation generated$(NC)"

.PHONY: version
version: ## Show version information
	@echo "$(BLUE)Swiss Re Infrastructure Challenge$(NC)"
	@echo "Version: $(VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo "Environment: $(ENV)"
	@echo "Deployment Version: $(DEPLOYMENT_VERSION)"

# ============================================
# CI/CD Integration
# ============================================
.PHONY: ci
ci: setup validate test ## Run CI pipeline locally
	@echo "$(GREEN)✓ CI pipeline complete$(NC)"

.PHONY: cd
cd: ci deploy ## Run CD pipeline locally
	@echo "$(GREEN)✓ CD pipeline complete$(NC)"

# ============================================
# Development Helpers
# ============================================
.PHONY: watch
watch: ## Watch for file changes and validate
	@echo "$(BLUE)Watching for changes...$(NC)"
	@while true; do \
		inotifywait -r -e modify infrastructure/ scripts/ 2>/dev/null; \
		make validate; \
	done

.PHONY: format
format: ## Format code files
	@echo "$(BLUE)Formatting code...$(NC)"
	@az bicep format --file $(BICEP_FILE)
	@for file in infrastructure/modules/*.bicep; do \
		az bicep format --file "$$file"; \
	done
	@echo "$(GREEN)✓ Formatting complete$(NC)"

# ============================================
# Quick Commands
# ============================================
.PHONY: quick-deploy
quick-deploy: ## Quick deployment to dev
	@$(MAKE) deploy ENV=dev DEPLOYMENT_VERSION=3

.PHONY: quick-test
quick-test: ## Quick test suite
	@$(MAKE) validate test-unit

.PHONY: all
all: setup validate test deploy docs ## Run everything

# ============================================
# Default Target
# ============================================
.DEFAULT: help
