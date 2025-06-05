# Environment Common Configurations

Shared provider configuration templates used across all environments and services.

## Directory Contents

- `aws_provider.tf`: AWS provider configuration template
- `helm_provider.tf`: Helm provider configuration template

## Purpose

Provides DRY (Don't Repeat Yourself) provider configurations that are:
- Generated automatically by Terragrunt in each service directory
- Consistent across environments
- Centrally managed for easy updates

## Configuration Files

### AWS Provider (`aws_provider.tf`)
- **Region**: us-east-1
- **Authentication**: AWS credentials file with "tyler" profile
- **Usage**: Generated in all service directories

### Helm Provider (`helm_provider.tf`)
- **Authentication**: EKS cluster credentials via AWS CLI
- **Usage**: Generated only in kubernetes-addons service
- **Dependencies**: Requires `var.eks_name` from EKS dependency

## Generation Syntax

```hcl
generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents  = file(find_in_parent_folders("_envcommon/aws_provider.tf"))
}
```
