# Makefile Usage Guide

## Overview

This Makefile provides automated build, test, and deployment workflows for the Swiss Re Infrastructure Challenge project. It simplifies common tasks and ensures consistent execution across different environments.

## Prerequisites

Before using the Makefile, ensure you have the following tools installed:

- **Azure CLI** (2.50+)
- **Bicep CLI** (0.20+)
- **Python** (3.9+)
- **Git** (2.30+)
- **Bash** (4.0+)
- **PowerShell Core** (7.0+) - Optional

## Quick Start

### 1. Initial Setup

    # Install required tools and dependencies
    make setup

    # Verify all tools are installed
    make check-tools

    # Login to Azure
    make login

### 2. Basic Commands

    # Show help and available commands
    make help

    # Validate all infrastructure code
    make validate

    # Run all tests
    make test

    # Deploy to development
    make deploy ENV=dev DEPLOYMENT_VERSION=3

    # Check deployment status
    make status

## Available Targets

### Setup & Prerequisites

| Command | Description |
|---------|-------------|
| `make setup` | Install required tools and dependencies |
| `make check-tools` | Verify all required tools are installed |
| `make login` | Login to Azure subscription |

### Validation

| Command | Description |
|---------|-------------|
| `make validate` | Run all validation checks |
| `make validate-bicep` | Validate Bicep templates |
| `make validate-scripts` | Validate shell and Python scripts |
| `make validate-parameters` | Validate parameter JSON files |
| `make check-warnings` | Ensure zero warnings in Bicep code |
| `make lint` | Run linters on all code |

### Testing

| Command | Description |
|---------|-------------|
| `make test` | Run all test suites |
| `make test-unit` | Run unit tests only |
| `make test-integration` | Run integration tests only |
| `make test-security` | Run security tests only |
| `make test-compliance` | Test Swiss Re compliance requirements |

### Build

| Command | Description |
|---------|-------------|
| `make build` | Build ARM templates from Bicep |
| `make format` | Format all Bicep files |

### Deployment

| Command | Description |
|---------|-------------|
| `make deploy` | Full deployment pipeline |
| `make what-if` | Preview deployment changes |
| `make create-rg` | Create resource group |
| `make deploy-infrastructure` | Deploy infrastructure only |
| `make post-deploy` | Run post-deployment validation |
| `make rollback` | Rollback to last successful deployment |

### Monitoring & Operations

| Command | Description |
|---------|-------------|
| `make status` | Check deployment status |
| `make logs` | View deployment logs |
| `make health-check` | Run health check |
| `make costs` | Show estimated costs |

### Cleanup

| Command | Description |
|---------|-------------|
| `make clean` | Clean build artifacts |
| `make destroy` | Destroy all resources (WARNING: Destructive!) |

### Documentation

| Command | Description |
|---------|-------------|
| `make docs` | Generate documentation |
| `make version` | Show version information |

### CI/CD Integration

| Command | Description |
|---------|-------------|
| `make ci` | Run CI pipeline locally |
| `make cd` | Run CD pipeline locally |

### Development Helpers

| Command | Description |
|---------|-------------|
| `make watch` | Watch for file changes and validate |
| `make quick-deploy` | Quick deployment to dev |
| `make quick-test` | Quick test suite |
| `make all` | Run everything |

## Environment Variables

The Makefile uses the following environment variables:

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `ENV` | Target environment | `dev` | `dev`, `prod` |
| `DEPLOYMENT_VERSION` | Infrastructure version to deploy | `3` | `1`, `2`, `3` |
| `RESOURCE_GROUP` | Azure resource group name | Auto-generated | Any valid name |
| `LOCATION` | Azure region | `westeurope` | Any Azure region |
| `SUBSCRIPTION_ID` | Azure subscription ID | Current subscription | Valid subscription ID |

## Usage Examples

### Development Workflow

    # 1. Make changes to infrastructure code
    vim infrastructure/modules/vm.bicep

    # 2. Validate changes
    make validate

    # 3. Run tests
    make test

    # 4. Preview deployment
    make what-if ENV=dev

    # 5. Deploy to development
    make deploy ENV=dev DEPLOYMENT_VERSION=3

    # 6. Verify deployment
    make health-check ENV=dev

### Production Deployment

    # 1. Validate everything
    make validate test

    # 2. Preview changes
    make what-if ENV=prod DEPLOYMENT_VERSION=3

    # 3. Deploy to production (requires confirmation)
    make deploy ENV=prod DEPLOYMENT_VERSION=3

    # 4. Monitor deployment
    make status ENV=prod
    make logs ENV=prod

    # 5. If issues arise, rollback
    make rollback ENV=prod

### Testing Workflow

    # Run all tests
    make test

    # Run specific test suites
    make test-unit        # Unit tests only
    make test-integration # Integration tests
    make test-security    # Security tests
    make test-compliance  # Compliance tests

    # Quick test for development
    make quick-test

### Maintenance Tasks

    # Check costs
    make costs ENV=prod

    # Generate documentation
    make docs

    # Clean up build artifacts
    make clean

    # Format code
    make format

    # Check version
    make version

## Advanced Usage

### Custom Resource Groups

    # Deploy to custom resource group
    RESOURCE_GROUP=rg-custom make deploy ENV=dev

### Different Azure Subscriptions

    # Deploy to specific subscription
    SUBSCRIPTION_ID=xxx-xxx-xxx make deploy ENV=prod

### CI/CD Pipeline Integration

    # In GitHub Actions
    - name: Run CI Pipeline
      run: make ci

    # In Azure DevOps
    - script: make cd
      displayName: 'Run CD Pipeline'

### Watch Mode for Development

    # Automatically validate on file changes
    make watch

## Troubleshooting

### Common Issues and Solutions

#### Deployment Fails

    # 1. Check deployment logs
    make logs ENV=dev

    # 2. Validate templates
    make validate

    # 3. Run what-if analysis
    make what-if ENV=dev

    # 4. If needed, rollback
    make rollback ENV=dev

#### Tests Fail

    # 1. Run individual test suites to isolate issue
    make test-unit
    make test-integration

    # 2. Validate scripts
    make validate-scripts

    # 3. Check parameters
    make validate-parameters

#### Authentication Issues

    # Re-login to Azure
    make login

    # Verify subscription
    az account show

#### Resource Group Already Exists

    # Option 1: Use existing resource group
    make deploy-infrastructure ENV=dev

    # Option 2: Delete and recreate
    make destroy ENV=dev
    make deploy ENV=dev

## Best Practices

1. **Always validate before deploying:**

    make validate && make deploy

2. **Use what-if for production:**

    make what-if ENV=prod

3. **Run tests after changes:**

    make test

4. **Clean up regularly:**

    make clean

5. **Document changes:**

    make docs

## Safety Features

- **Production deployments require confirmation** - The Makefile will prompt for confirmation before deploying to production
- **Destroy command requires typing 'DESTROY'** - Prevents accidental resource deletion
- **Rollback capability** - Can rollback to last successful deployment
- **What-if analysis** - Preview changes before applying

## Integration with CI/CD

The Makefile is designed to work seamlessly with CI/CD pipelines:

### GitHub Actions

    - name: Setup and Validate
      run: |
        make setup
        make validate

    - name: Run Tests
      run: make test

    - name: Deploy
      run: make deploy ENV=${{ github.event.inputs.environment }}

### Azure DevOps

    - script: make ci
      displayName: 'Run CI Pipeline'

    - script: make deploy ENV=$(environment)
      displayName: 'Deploy Infrastructure'

### Local Development

    # Run full CI/CD pipeline locally
    make cd

## Version Information

- **Makefile Version:** 1.0.0
- **Compatible with:** Swiss Re Infrastructure Challenge v3
- **Tested on:** Ubuntu 20.04+, macOS 12+, WSL2

## Support

For issues or questions about the Makefile:

1. Check the help command: `make help`
2. Review this documentation
3. Check the troubleshooting section
4. Consult the main project README.md

## License

This Makefile is part of the Swiss Re Infrastructure Challenge project and follows the same license terms.

---

**Note:** This Makefile is designed for the base branch of the Swiss Re Infrastructure Challenge. For the enterprise version with additional features, refer to the enterprise branch documentation.
