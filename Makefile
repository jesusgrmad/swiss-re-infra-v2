# Swiss Re Infrastructure - Makefile
# Author: Jesus Gracia
# Date: August 18, 2025

.PHONY: help validate deploy test clean

help:
	@echo 'Swiss Re Infrastructure Makefile'
	@echo 'Author: Jesus Gracia'
	@echo ''
	@echo 'Available targets:'
	@echo '  validate   - Validate all templates'
	@echo '  deploy     - Deploy infrastructure (ENV=dev|test|prod)'
	@echo '  test       - Run all tests'
	@echo '  clean      - Clean temporary files'
	@echo '  help       - Show this help'

validate:
	@echo 'Validating templates...'
	@bash scripts/validate.sh

deploy: validate
	@echo 'Deploying to environment: $(ENV)'
	@bash scripts/deploy.sh $(ENV) $(VERSION)

test:
	@echo 'Running tests...'
	@bash scripts/health-check.sh $(ENV)

clean:
	@echo 'Cleaning temporary files...'
	@rm -f *.json.lock
	@rm -f deployment-*.json
	@echo 'Clean complete'

# Default environment variables
ENV ?= dev
VERSION ?= 3