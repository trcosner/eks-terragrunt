# Infrastructure Configuration

Environment-specific Terragrunt configurations for deploying EKS infrastructure.

## Directory Structure

```
infrastructure/
├── _envcommon/              # Shared provider configurations
├── dev/                     # Development environment
│   ├── vpc/                # VPC configuration
│   ├── eks/                # EKS cluster configuration
│   └── kubernetes-addons/  # Add-ons configuration
└── staging/                 # Staging environment (same structure)
```

## Deployment Order

Infrastructure dependencies require deployment in sequence:

1. **VPC**: Network foundation
2. **EKS**: Kubernetes cluster  
3. **Add-ons**: Cluster components

```bash
cd infrastructure/dev
terragrunt apply --all
```

## Configuration Pattern

Each service uses:
- Source module from `infrastructure-modules/`
- Environment variables from `env.hcl`
- Dependencies via Terragrunt outputs
- Generated providers for AWS/Helm

## State Management

- **Backend**: S3 with DynamoDB locking
- **Path**: `{environment}/{service}/terraform.tfstate`
- **Encryption**: Enabled
