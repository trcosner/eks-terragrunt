# Infrastructure Root Configuration

Root-level Terragrunt configuration with shared backend and provider settings for multi-environment EKS infrastructure.

## Directory Structure

```
infrastructure/
├── backend.tf              # S3 backend configuration for remote state
├── provider.tf             # AWS provider configuration
├── terragrunt.hcl          # Root Terragrunt configuration
├── dev/                    # Development environment configuration
│   ├── env.hcl            # Environment-specific variables
│   ├── vpc/               # VPC infrastructure
│   ├── eks/               # EKS cluster
│   ├── acm-certificate/   # SSL certificates
│   └── kubernetes-addons/ # Platform services
├── staging/               # Staging environment configuration
│   └── [same structure as dev]
└── _envcommon/           # Shared provider configurations
    ├── aws_provider.tf   # Common AWS provider settings
    ├── helm_provider.tf  # Helm provider for Kubernetes deployments
    └── kubernetes_provider.tf # Kubernetes provider configuration
```

## Usage

This directory contains environment-specific Terragrunt configurations that reference the reusable modules in `infrastructure-modules/`. Each environment (dev, staging) has its own isolated infrastructure while sharing common patterns and configurations.

### Backend Configuration

- **S3 State Storage**: Centralized state management with versioning and encryption
- **DynamoDB Locking**: Prevents concurrent Terraform operations
- **State Isolation**: Each environment maintains separate state files

### Provider Management

- **Shared Providers**: Common provider configurations in `_envcommon/`
- **Environment Variables**: Environment-specific settings in `env.hcl`
- **Automatic Generation**: Terragrunt generates provider configurations per module

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
