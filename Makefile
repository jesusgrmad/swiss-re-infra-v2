# Swiss Re Infrastructure Challenge - Makefile
# Author: Jesus Gracia
# Date: August 18, 2025
# Version: 3.0.0

.PHONY: help validate deploy test clean logs security

# Default target
help:
	@echo 'Swiss Re Infrastructure Makefile'
	@echo 'Author: Jesus Gracia'
	@echo ''
	@echo 'Available targets:'
	@echo '  validate   - Validate all templates'
	@echo '  deploy     - Deploy infrastructure'
	@echo '  test       - Run all tests'
	@echo '  security   - Run security tests'
	@echo '  logs       - Show recent logs'
	@echo '  clean      - Clean temporary files'
	@echo '  help       - Show this help message'

# Validate templates
validate:
	@echo 'Validating templates...'
	@bash scripts/validate.sh

# Deploy infrastructure
deploy: validate
	@echo 'Deploying...'
	@bash scripts/deploy.sh

# Run all tests
test:
	@echo 'Running test suite...'
	@bash tests/run-all-tests.sh

# Run security tests
security:
	@echo 'Running security tests...'
	@bash tests/security/test-security.sh

# Show recent logs
logs:
	@echo 'Recent deployment logs:'
	@ls -la logs/*.log 2>/dev/null || echo 'No logs found'

# Clean temporary files
clean:
	@echo 'Cleaning temporary files...'
	@rm -f logs/*.tmp
	@rm -f *.json.lock
	@rm -f deployment-output*.json
	@echo 'Cleanup complete'