# Dev Environment Configuration

Terragrunt configuration for the development environment EKS infrastructure.

## Directory Structure

```
infrastructure/dev/
├── env.hcl                 # Environment variables
├── vpc/                    # VPC and networking
├── eks/                    # EKS cluster
└── kubernetes-addons/      # Cluster add-ons
```

## Infrastructure Components

### 1. VPC
- **Network**: Multi-AZ setup with private/public subnets
- **Dependencies**: None (foundational layer)

### 2. EKS Cluster  
- **Name**: dev-demo
- **Version**: 1.33
- **Nodes**: t3a.xlarge instances (1-5 scaling)
- **Dependencies**: VPC subnets

### 3. Kubernetes Add-ons
- **Cluster Autoscaler**: Enabled with Helm chart
- **Dependencies**: EKS cluster and OIDC provider

## Deployment

Deploy in order due to dependencies:

```bash
cd infrastructure/dev
terragrunt run-all apply
```

## Environment Variables

From `env.hcl`:
```hcl
locals {
    env = "dev"
}
```

Used for resource naming, tagging, and state organization.
