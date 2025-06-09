# EKS Terragrunt Infrastructure

A production-ready infrastructure-as-code setup for deploying Amazon EKS clusters using Terragrunt and Terraform. This repository provides a modular, DRY (Don't Repeat Yourself) approach to managing EKS infrastructure across multiple environments with comprehensive testing and cost optimization.

## 🏗️ Architecture Overview

This repository follows a modular architecture pattern that separates reusable Terraform modules from environment-specific configurations:

```
├── bootstrap/                 # Initial setup (S3, DynamoDB, Route53, IAM policies)
├── infrastructure-modules/    # Reusable Terraform modules
│   ├── vpc/                  # VPC with public/private subnets across AZs
│   ├── eks/                  # EKS cluster and managed node groups
│   ├── kubernetes-addons/    # Kubernetes add-ons (autoscaler, ALB controller)
│   ├── acm-certificate/      # SSL certificates for domains
│   └── route53/              # DNS hosted zone management
├── infrastructure/           # Environment-specific Terragrunt configurations
│   ├── dev/                 # Development environment
│   ├── staging/             # Staging environment
│   └── _envcommon/          # Shared provider configurations
└── infrastructure-tests/      # Professional testing suite with cost optimization
    ├── scripts/             # Cost-optimized test scripts
    ├── manifests/           # Kubernetes test manifests
    └── docs/                # Testing documentation and cost analysis
```

### Current Deployment Architecture

**Development Environment:**
- **Network**: 2-AZ VPC (us-east-1a, us-east-1b) with public/private subnets
- **EKS**: Single-node deployment for cost optimization (scales 1-5 nodes)
- **Domain**: `dev.example.com` with wildcard certificate (`*.dev.example.com`)
- **Cost**: Optimized for development with minimal resource usage

**Staging Environment:**
- **Network**: 2-AZ VPC (us-east-1a, us-east-1b) with public/private subnets
- **EKS**: Single-node deployment for cost optimization (scales 1-5 nodes)
- **Domain**: `staging.example.com` with wildcard certificate (`*.staging.example.com`)
- **Cost**: Optimized for testing with controlled resource usage

### Future Multi-AZ Enhancement Plans

**Planned Multi-AZ Deployment:**
- **Geolocation-based Routing**: Route53 geolocation routing for optimal performance
- **Regional Deployment**: Multiple regions with automated failover
- **Subdomain Strategy**: 
  - `app.dev.example.com`, `tools.dev.example.com` for development services
  - `api.staging.example.com`, `admin.staging.example.com` for staging services
- **VPN Testing**: Test different regions via VPN to validate geolocation routing
- **Load Balancing**: Geographic load distribution for global scale

## 🚀 Features

### Infrastructure
- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **Modular Design**: Reusable Terraform modules for all components
- **DRY Configuration**: Terragrunt eliminates code duplication across environments
- **Remote State Management**: S3 backend with DynamoDB locking for state consistency
- **Cost-Optimized Deployment**: Single-node clusters with auto-scaling capabilities

### Security & Networking
- **Security Best Practices**: Private subnets, IAM roles, and OIDC integration
- **SSL/TLS**: Automated SSL certificate management with ACM
- **DNS Management**: Route53 hosted zone with external domain support
- **Network Isolation**: Proper subnet segmentation and security groups

### Kubernetes & Scalability
- **Auto-scaling**: Kubernetes cluster autoscaler for dynamic node scaling
- **Load Balancing**: AWS Load Balancer Controller for multi-app/service load balancing
- **DNS Automation**: External DNS for automatic Route53 record management
- **Cost-Controlled Scaling**: Configurable scaling limits for cost management
- **Resource Management**: Proper resource requests and limits for cost optimization

### Testing & Validation
- **Professional Testing Suite**: Multi-tier testing with cost optimization
- **Zero-Cost Smoke Tests**: Basic functionality validation without AWS costs
- **Cost-Optimized Integration Tests**: End-to-end validation with minimal costs
- **Autoscaler Stress Testing**: Controlled scaling tests with cost monitoring
- **Comprehensive Documentation**: Detailed testing guides and cost analysis

## 📋 Prerequisites

Before getting started, ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) (configured with appropriate credentials)
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (>= 0.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (for cluster management)
- [Helm](https://helm.sh/docs/intro/install/) (for Kubernetes package management)

## 🛠️ Quick Start

### 1. Bootstrap the Infrastructure

First, create the foundational infrastructure including S3, DynamoDB, Route53, and shared IAM policies:

```bash
cd bootstrap

# Configure your domain
cp domain.auto.tfvars.example domain.auto.tfvars
# Edit domain.auto.tfvars with your actual domain name

# Deploy bootstrap infrastructure
terragrunt init
terragrunt plan
terragrunt apply

# Get nameservers for domain configuration
terragrunt output hosted_zone_name_servers
```

**Important**: Update your domain registrar with the nameservers from the output above.

### 2. Configure Domain DNS

Before proceeding, configure your domain's nameservers:

1. **Log into your domain registrar** (Namecheap, GoDaddy, etc.)
2. **Find DNS/Nameserver settings** for your domain
3. **Change to Custom DNS** and enter the 4 AWS nameservers
4. **Wait for propagation** (15 minutes to 48 hours)

Verify DNS propagation:
```bash
# Check if your domain resolves to AWS nameservers
nslookup -type=NS your-domain.com
```
dig NS your-domain.com
```

### 3. Deploy Infrastructure

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

# Deploy SSL certificates (requires DNS to be configured)
cd ../acm-certificate
terragrunt plan
terragrunt apply

# Deploy Kubernetes add-ons with Load Balancer Controller
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

### 5. Verify and Test Infrastructure

After deploying your infrastructure, validate it using our comprehensive testing suite:

```bash
# Quick health check (30 seconds, $0.00)
cd testing
./scripts/smoke-test.sh dev

# Cost-optimized integration test (10 minutes, ~$0.05)
./scripts/integration-test.sh dev

# Full end-to-end validation (20 minutes, ~$0.15-0.25)
./scripts/test-suite.sh dev
```

For detailed testing information, see [infrastructure-tests/README.md](infrastructure-tests/README.md).

### 6. Deploy Sample Applications

Deploy sample applications to test your cluster:

```bash
# Basic application deployment
kubectl apply -f infrastructure-tests/manifests/general/deployment.yaml

# Test autoscaler with resource-intensive workload
kubectl apply -f infrastructure-tests/manifests/load/high-cpu-deployment.yaml

# Test External DNS with sample application
kubectl apply -f examples/external-dns-example.yaml

# Validate External DNS is working
./scripts/validate-external-dns.sh example.com dev

# Check DNS records
dig app.dev.example.com
dig api.dev.example.com
```

## 📁 Directory Structure

### Infrastructure Modules (`infrastructure-modules/`)

Contains reusable Terraform modules:

- **`vpc/`**: Creates VPC with public/private subnets, NAT gateways, and route tables
- **`eks/`**: Provisions EKS cluster, managed node groups, and IAM roles
- **`kubernetes-addons/`**: Installs essential Kubernetes add-ons like cluster autoscaler and AWS Load Balancer Controller

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
- **AWS Load Balancer Controller**: Efficient ingress management with ALB/NLB provisioning
- **Cost Monitoring**: Resource usage tracking and scaling metrics
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

# Test load balancer
kubectl apply -f demo/ingress-example.yaml
kubectl get ingress

# Check services
kubectl get services
```

## 🧪 Testing & Validation

This repository includes a professional testing suite with cost optimization:

### Testing Tiers

| Test Type | Duration | Cost | Purpose |
|-----------|----------|------|---------|
| **Smoke Test** | 30s | $0.00 | Basic health check, zero AWS costs |
| **Integration Test** | 10min | ~$0.05 | End-to-end with internal ALB |
| **Autoscaler Test** | 15min | ~$0.10-0.30 | Controlled scaling validation |
| **Full Test Suite** | 20min | ~$0.15-0.25 | Comprehensive validation |

### Key Testing Features

- **Zero-cost basic validation** - No additional AWS resource creation
- **Cost-optimized integration tests** - Minimal resource usage with automatic cleanup
- **Professional test reports** - Detailed output with cost summaries
- **Automatic cleanup** - All test resources removed after completion
- **Comprehensive coverage** - Multi-AZ, autoscaling, load balancing, SSL/DNS

### Quick Test Commands

```bash
cd testing

# Zero-cost cluster health check
./scripts/smoke-test.sh

# Test autoscaler functionality  
./scripts/autoscaler-stress-test.sh

# Full infrastructure validation
./scripts/test-suite.sh dev
```

For complete testing documentation, see [infrastructure-tests/docs/](infrastructure-tests/docs/).

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