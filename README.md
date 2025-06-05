# EKS Terragrunt Infrastructure

A production-ready infrastructure-as-code setup for deploying Amazon EKS clusters using Terragrunt and Terraform. This repository provides a modular, DRY (Don't Repeat Yourself) approach to managing EKS infrastructure across multiple environments.

## 🏗️ Architecture Overview

This repository follows a modular architecture pattern that separates reusable Terraform modules from environment-specific configurations:

```
├── bootstrap/                 # Initial setup for Terraform state backend
├── infrastructure-modules/    # Reusable Terraform modules
│   ├── vpc/                  # VPC with public/private subnets
│   ├── eks/                  # EKS cluster and node groups
│   └── kubernetes-addons/    # Kubernetes add-ons (cluster autoscaler, etc.)
├── infrastructure/           # Environment-specific Terragrunt configurations
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── _envcommon/          # Shared provider configurations
└── demo/                    # Sample Kubernetes applications
```

## 🚀 Features

- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **Modular Design**: Reusable Terraform modules for VPC, EKS, and Kubernetes add-ons
- **DRY Configuration**: Terragrunt eliminates code duplication across environments
- **Remote State Management**: S3 backend with DynamoDB locking for state consistency
- **Security Best Practices**: Private subnets, IAM roles, and OIDC integration
- **Auto-scaling**: Kubernetes cluster autoscaler for dynamic node scaling
- **Production Ready**: Includes monitoring, logging, and security configurations

## 📋 Prerequisites

Before getting started, ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) (configured with appropriate credentials)
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (>= 0.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (for cluster management)
- [Helm](https://helm.sh/docs/intro/install/) (for Kubernetes package management)

## 🛠️ Quick Start

### 1. Bootstrap the Infrastructure

First, create the S3 bucket and DynamoDB table for Terraform state management:

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

**Note**: After bootstrapping, update the `bucket_suffix` in `infrastructure/terragrunt.hcl` with the output from the bootstrap step.

### 2. Deploy Infrastructure

Choose your target environment (dev or staging) and deploy the infrastructure:

```bash
# Deploy VPC
cd infrastructure/staging/vpc
terragrunt plan
terragrunt apply

# Deploy EKS cluster
cd ../eks
terragrunt plan
terragrunt apply

# Deploy Kubernetes add-ons
cd ../kubernetes-addons
terragrunt plan
terragrunt apply
```

### 3. Configure kubectl

After the EKS cluster is deployed, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name staging-demo
```

### 4. Deploy Sample Application

Deploy a sample nginx application to test your cluster:

```bash
kubectl apply -f demo/deployment.yaml
kubectl get pods
```

## 📁 Directory Structure

### Infrastructure Modules (`infrastructure-modules/`)

Contains reusable Terraform modules:

- **`vpc/`**: Creates VPC with public/private subnets, NAT gateways, and route tables
- **`eks/`**: Provisions EKS cluster, managed node groups, and IAM roles
- **`kubernetes-addons/`**: Installs essential Kubernetes add-ons like cluster autoscaler

### Infrastructure Configurations (`infrastructure/`)

Environment-specific Terragrunt configurations:

- **`dev/`**: Development environment settings
- **`staging/`**: Staging environment settings
- **`_envcommon/`**: Shared provider configurations
- **`terragrunt.hcl`**: Root Terragrunt configuration with remote state setup

### Key Configuration Files

- **`env.hcl`**: Environment-specific variables and naming
- **`terragrunt.hcl`**: Service-specific configurations and dependencies
- **`aws_provider.tf`**: AWS provider configuration template
- **`helm_provider.tf`**: Helm provider configuration template

## 🔧 Configuration

### Environment Variables

Each environment has its own `env.hcl` file defining:

```hcl
locals {
    env = "staging"  # Environment name used for resource naming
}
```

### EKS Configuration

The EKS module supports customizable:

- **Kubernetes Version**: Specify EKS version (e.g., "1.33")
- **Node Groups**: Configure instance types, scaling, and capacity type
- **Networking**: VPC and subnet configuration
- **Add-ons**: Cluster autoscaler, monitoring, logging

### VPC Configuration

The VPC module creates:

- **Public Subnets**: For load balancers and NAT gateways
- **Private Subnets**: For EKS nodes and applications
- **Internet Gateway**: For internet access
- **NAT Gateways**: For private subnet internet access

## 🔐 Security Features

- **Private Node Groups**: EKS nodes run in private subnets
- **IAM Roles**: Least-privilege access with service-linked roles
- **OIDC Integration**: Kubernetes service accounts with AWS IAM
- **Network Security**: Security groups with minimal required access
- **Encryption**: EKS secrets encryption and EBS volume encryption

## 🔍 Monitoring and Observability

The infrastructure includes:

- **CloudWatch Logging**: EKS control plane logs
- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **AWS Load Balancer Controller**: Efficient ingress management
- **Metrics Server**: Pod and node metrics collection

## 🚀 Deployment Workflow

### Single Environment Deployment

```bash
# Deploy all components in order (updated syntax for Terragrunt 0.50+)
cd infrastructure/staging
terragrunt plan --all    # Review all changes
terragrunt apply --all   # Deploy all components
```

### Component-Specific Deployment

```bash
# Deploy only VPC
cd infrastructure/staging/vpc
terragrunt apply

# Deploy only EKS (requires VPC)
cd infrastructure/staging/eks
terragrunt apply
```

### Dependency Management

Terragrunt automatically handles dependencies between components:

- EKS depends on VPC (uses VPC outputs for subnets)
- Kubernetes add-ons depend on EKS (uses EKS outputs for cluster info)

## 🧪 Testing

After deployment, verify your cluster:

```bash
# Check cluster status
kubectl get nodes

# Deploy test application
kubectl apply -f demo/deployment.yaml

# Check pod status
kubectl get pods

# Check services
kubectl get services
```

## 🔄 Updating Infrastructure

To update infrastructure:

1. Modify the relevant Terragrunt configuration
2. Run `terragrunt plan` to review changes
3. Run `terragrunt apply` to apply changes

For module updates:

1. Update the module code in `infrastructure-modules/`
2. Run `terragrunt apply` in the relevant environment directory

## 🗑️ Cleanup

To destroy infrastructure:

```bash
# Destroy in reverse order
cd infrastructure/staging/kubernetes-addons
terragrunt destroy

cd ../eks
terragrunt destroy

cd ../vpc
terragrunt destroy
```

Or destroy all at once:

```bash
cd infrastructure/staging
terragrunt destroy --all --non-interactive
```

## 🆘 Troubleshooting

### Common Issues

**Terragrunt command not found**
```bash
brew install terragrunt
```

**kubectl cannot connect to cluster**
```bash
aws eks update-kubeconfig --region us-east-1 --name [CLUSTER_NAME]
```

**State lock conflicts**
```bash
terragrunt force-unlock [LOCK_ID]
```

**Clear Terragrunt caches**
```bash
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +
```