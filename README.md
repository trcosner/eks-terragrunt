# EKS Terragrunt Infrastructure

A production-ready infrastructure-as-code setup for deploying Amazon EKS clusters using Terragrunt and Terraform. This repository provides a modular, DRY (Don't Repeat Yourself) approach to managing EKS infrastructure across multiple environments with comprehensive testing, cost optimization, and automated documentation generation.

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

### Documentation & Development
- **Automated Documentation**: terraform-docs integration with pre-commit hooks
- **AI-Powered Documentation**: GitHub Copilot integration for intelligent module documentation
- **Live Documentation**: Always up-to-date documentation that syncs with code changes
- **Pre-commit Hooks**: Automatic code formatting, validation, and documentation updates
- **Professional Testing Suite**: Multi-tier testing with comprehensive validation

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

## 📋 Prerequisites

Before getting started, ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) (configured with appropriate credentials)
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (>= 0.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (for cluster management)
- [Helm](https://helm.sh/docs/intro/install/) (for Kubernetes package management)

### Optional Development Tools

For enhanced development experience:

- [terraform-docs](https://terraform-docs.io/) (automatic documentation generation)
- [pre-commit](https://pre-commit.com/) (code quality and validation hooks)
- [GitHub CLI with Copilot](https://cli.github.com/) (AI-powered documentation)
- [tflint](https://github.com/terraform-linters/tflint) (Terraform linting)

**Quick setup for development tools:**
```bash
# Run the setup script (installs pre-commit, terraform-docs, tflint)
./scripts/setup-precommit.sh
```

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

Contains reusable Terraform modules with auto-generated documentation:

- **`vpc/`**: Creates VPC with public/private subnets, NAT gateways, and route tables
- **`eks/`**: Provisions EKS cluster, managed node groups, and IAM roles
- **`kubernetes-addons/`**: Installs essential Kubernetes add-ons (autoscaler, ALB controller, External DNS, monitoring)
- **`acm-certificate/`**: Manages SSL/TLS certificates for domains
- **`route53/`**: DNS hosted zone management and configuration

Each module includes comprehensive terraform-docs generated documentation with:
- Requirements and provider versions
- All input variables with descriptions and types
- All outputs with descriptions
- Resource listings with links to AWS documentation

### Infrastructure Configurations (`infrastructure/`)

Environment-specific Terragrunt configurations:

- **`dev/`**: Development environment settings (cost-optimized single node)
- **`staging/`**: Staging environment settings (cost-optimized single node)
- **`_envcommon/`**: Shared provider configurations and common resources
- **`terragrunt.hcl`**: Root Terragrunt configuration with remote state setup

### Bootstrap Infrastructure (`bootstrap/`)

Initial setup for foundational AWS resources:

- **S3 Backend**: Terraform state storage with versioning and encryption
- **DynamoDB**: State locking table for concurrent access protection
- **Route53**: DNS hosted zone for domain management
- **IAM Policies**: Basic permissions and service-linked roles

### Automation & Scripts (`scripts/`)

Development and operational automation:

- **`setup-precommit.sh`**: Installs and configures pre-commit hooks with terraform-docs
- **`update-readmes.sh`**: Regenerates all module documentation with terraform-docs
- **`ai-docs-generator.sh`**: AI-powered documentation using GitHub Copilot
- **`validate-external-dns.sh`**: DNS validation and testing utilities
- **`sanitize-sensitive-data.sh`**: Security utilities for data sanitization

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
- **IRSA**: IAM Roles for Service Accounts integration

### VPC Configuration

The VPC module creates:

- **Public Subnets**: For load balancers and NAT gateways (10.0.1.0/24, 10.0.2.0/24)
- **Private Subnets**: For EKS nodes and applications (10.0.11.0/24, 10.0.12.0/24)
- **Internet Gateway**: For internet access
- **NAT Gateways**: For private subnet internet access (one per AZ)
- **Route Tables**: Proper routing for public and private subnets

### Kubernetes Add-ons Configuration

The kubernetes-addons module includes:

- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **AWS Load Balancer Controller**: ALB/NLB provisioning for ingress
- **External DNS**: Automatic Route53 record management for services
- **EBS CSI Driver**: Persistent volume support for stateful applications
- **Pod Security Standards**: Kubernetes security policies
- **Network Policies**: Network-level security controls
- **Secrets Management**: AWS Secrets Manager integration
- **Monitoring**: CloudWatch and Prometheus integration

### Documentation Configuration

The project uses automated documentation generation:

- **terraform-docs**: Generates comprehensive module documentation
- **Pre-commit hooks**: Automatically updates docs on every commit
- **AI documentation**: GitHub Copilot integration for intelligent explanations
- **Configuration**: `.terraform-docs.yml` defines documentation format and structure

## 🔐 Security Features

- **Private Node Groups**: EKS nodes run in private subnets
- **IAM Roles**: Least-privilege access with service-linked roles
- **OIDC Integration**: Kubernetes service accounts with AWS IAM
- **Network Security**: Security groups with minimal required access
- **Encryption**: EKS secrets encryption and EBS volume encryption

## 🔍 Monitoring and Observability

The infrastructure includes comprehensive monitoring and observability:

- **CloudWatch Logging**: EKS control plane logs with retention policies
- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **AWS Load Balancer Controller**: Efficient ingress management with ALB/NLB provisioning
- **Cost Monitoring**: Resource usage tracking and scaling metrics
- **Metrics Server**: Pod and node metrics collection for HPA
- **External DNS**: Automatic DNS record management with monitoring
- **EBS CSI Driver**: Persistent volume metrics and monitoring
- **Pod Security**: Security policy monitoring and enforcement
- **Network Policies**: Network traffic monitoring and security

### Documentation and Development Experience

- **Auto-generated Documentation**: Every module has comprehensive terraform-docs generated documentation
- **Pre-commit Validation**: Automatic code formatting, linting, and documentation updates
- **AI-Powered Insights**: GitHub Copilot integration for intelligent code explanations
- **Testing Suite**: Comprehensive validation with cost optimization

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

### Development Workflow Validation

The project includes automated validation for development workflows:

- **Pre-commit hooks**: Validate Terraform code, format, and generate docs on every commit
- **terraform-docs**: Ensure documentation is always up-to-date with code changes
- **AI-powered validation**: GitHub Copilot integration for code quality insights
- **State consistency**: Scripts to validate Terragrunt state across environments

For complete testing documentation, see module-specific README files with terraform-docs generated sections.

## 📚 Documentation & Development Workflow

This project features automated documentation generation and developer-friendly workflows:

### Automated Documentation

- **terraform-docs Integration**: Every module automatically generates comprehensive documentation
- **Pre-commit Hooks**: Documentation updates automatically on every commit
- **AI-Powered Insights**: GitHub Copilot integration for intelligent code explanations
- **Live Documentation**: Documentation always stays in sync with code changes

### Documentation Structure

Each module includes:
- **Requirements**: Provider versions and dependencies
- **Providers**: Configured providers with versions
- **Resources**: All AWS resources with links to documentation
- **Inputs**: Variables with descriptions, types, defaults, and requirements
- **Outputs**: All outputs with clear descriptions

### Developer Setup

Get started with the full development environment:

```bash
# Install all development tools
./scripts/setup-precommit.sh

# This installs:
# - pre-commit (code quality hooks)
# - terraform-docs (documentation generation)
# - tflint (Terraform linting)
# - GitHub Copilot CLI (AI assistance)
```

### Pre-commit Features

When you commit code, pre-commit automatically:
- **Formats Terraform code** with `terraform fmt`
- **Validates Terraform syntax** with `terraform validate`
- **Updates documentation** with `terraform-docs`
- **Runs linting** with `tflint` for best practices
- **Formats Terragrunt files** with `terragrunt hclfmt`
- **Checks for security issues** and code quality

### AI-Powered Documentation

The project includes AI-enhanced documentation:
- **Intelligent explanations** of complex Terraform configurations
- **Architecture insights** powered by GitHub Copilot
- **Usage examples** and best practices
- **Security recommendations** and optimization tips

Example of viewing module documentation:
```bash
# View EKS module documentation
cat infrastructure-modules/eks/README.md

# View VPC module documentation  
cat infrastructure-modules/vpc/README.md

# All modules include terraform-docs generated sections
```

## 🔄 Updating Infrastructure

To update infrastructure:

1. **Modify configurations**: Update relevant Terragrunt or module configuration
2. **Review changes**: Run `terragrunt plan` to review changes
3. **Apply updates**: Run `terragrunt apply` to apply changes
4. **Documentation**: Pre-commit hooks automatically update documentation

### Module Development Workflow

For module updates:

1. **Edit module code** in `infrastructure-modules/`
2. **Documentation auto-updates** via pre-commit hooks when you commit
3. **Deploy updated modules** by running `terragrunt apply` in environment directories
4. **Validate changes** using the testing suite

### Documentation Workflow

The project uses automated documentation:

- **terraform-docs**: Automatically generates module documentation from code
- **Pre-commit hooks**: Updates documentation on every commit
- **AI insights**: GitHub Copilot provides intelligent explanations
- **Manual regeneration**: Use `./scripts/update-readmes.sh` to regenerate all docs

```bash
# Regenerate all module documentation
./scripts/update-readmes.sh

# Set up pre-commit hooks for automatic updates
./scripts/setup-precommit.sh

# View current documentation
# Each module's README.md contains comprehensive terraform-docs sections
```

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

**Pre-commit hooks not working**
```bash
# Reinstall pre-commit hooks
./scripts/setup-precommit.sh

# Or manually install
pre-commit install
```

**terraform-docs not updating**
```bash
# Manually regenerate documentation
./scripts/update-readmes.sh

# Check terraform-docs installation
terraform-docs --version
```

**Documentation out of sync**
```bash
# Force regenerate all module documentation
./scripts/update-readmes.sh

# Run pre-commit on all files
pre-commit run --all-files
```

### Getting Help

- **Module Documentation**: Each module in `infrastructure-modules/` has comprehensive README with terraform-docs generated sections
- **Configuration Examples**: Check environment-specific configs in `infrastructure/dev/` and `infrastructure/staging/`
- **Scripts**: Use automation scripts in `scripts/` directory for common tasks
- **Testing**: Run the testing suite to validate your infrastructure setup