# Bootstrap Infrastructure

## Overview

The bootstrap layer provides the foundational infrastructure required before deploying any application environments. This is a **one-time setup** that creates shared resources used across all environments (dev, staging, production).

### Architecture Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Bootstrap Infrastructure                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │   S3 Bucket │  │ DynamoDB     │  │     Route53 Hosted      │ │
│  │   (State)   │  │ (Locking)    │  │         Zone            │ │
│  └─────────────┘  └──────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            All Environment Infrastructure                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │     VPC     │  │     EKS     │  │    Kubernetes Addons    │ │
│  │    (dev)    │  │   (dev)     │  │        (dev)            │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Key Resources

| Resource | Purpose | Lifecycle |
|----------|---------|-----------|
| **S3 Bucket** | Terraform state storage with versioning and encryption | Permanent |
| **DynamoDB Table** | State locking to prevent concurrent operations | Permanent |
| **Route53 Hosted Zone** | DNS management for your domain | Permanent |
| **KMS Key** | Encryption for state files | Permanent |

> ⚠️ **Critical**: These resources should **never be destroyed** unless completely decommissioning the project

## Prerequisites

### Required Tools
- **AWS CLI** (>= 2.0) configured with administrative permissions
- **Terraform** (>= 1.0) installed and in PATH
- **jq** for JSON processing (optional but recommended)

### Required Permissions
Your AWS user/role needs the following permissions:
- `s3:*` - For state bucket management
- `dynamodb:*` - For state locking table
- `route53:*` - For hosted zone management
- `kms:*` - For encryption key management
- `iam:*` - For role and policy management

### Domain Requirements
- **Registered domain** from any registrar (Namecheap, GoDaddy, Cloudflare, etc.)
- **Access to DNS settings** at your registrar to update nameservers

## Quick Start

### 1. Domain Configuration

Copy and configure your domain settings:
```bash
# Copy the example configuration
cp domain.auto.tfvars.example domain.auto.tfvars

# Edit with your domain details
vim domain.auto.tfvars
```

Configure your domain in `domain.auto.tfvars`:
```hcl
# Replace with your actual domain
domain_name = "example.com"  

# Set to true for initial setup
create_hosted_zone = true

# Optional: Add tags for resource organization
tags = {
  Environment = "shared"
  Project     = "eks-terragrunt"
  Owner       = "devops-team"
}
```

### 2. Deploy Bootstrap Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply the configuration
terraform apply
```

**Expected deployment time**: 2-3 minutes

### 3. Configure Domain Nameservers

After successful deployment, retrieve your AWS nameservers:
```bash
# Get nameservers for your registrar
terraform output -json hosted_zone_name_servers | jq -r '.[]'
```

**Update your domain registrar**:
1. Log into your domain registrar (Namecheap, GoDaddy, etc.)
2. Navigate to DNS/Nameserver settings for your domain
3. Change from "Registrar DNS" to "Custom DNS"
4. Enter all 4 AWS nameservers from the output above

### 4. Verify DNS Propagation

DNS changes typically take 15 minutes to 48 hours to propagate globally:

```bash
# Check nameserver propagation
dig NS your-domain.com

# Alternative check
nslookup -type=NS your-domain.com

# Check from multiple locations
curl -s "https://dns.google/resolve?name=your-domain.com&type=NS" | jq '.Answer[].data'
```

## State Management

### Remote State Configuration

After bootstrap deployment, all subsequent Terraform configurations use this remote state:

```hcl
# Example terragrunt.hcl configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "your-terraform-state-bucket"
    key            = "path/to/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "your-terraform-locks"
  }
}
```

### State Bucket Features
- **Versioning**: Enabled for state file history
- **Encryption**: AES-256 server-side encryption
- **Public Access**: Completely blocked
- **Lifecycle**: Intelligent tiering for cost optimization

## Outputs

| Output | Description |
|--------|-------------|
| `s3_bucket_name` | Terraform state bucket name |
| `dynamodb_table_name` | State locking table name |
| `hosted_zone_id` | Route53 hosted zone ID |
| `hosted_zone_name_servers` | Nameservers to configure at your registrar |
| `domain_name` | Your configured domain name |

## Domain Registrar CLI Tools

### Namecheap
No official CLI, but you can use:
- **namecheap-cli** (unofficial): `npm install -g namecheap-cli`
- **Web interface**: https://ap.www.namecheap.com/

### Other Registrars
- **GoDaddy**: Has official API and CLI tools
- **Cloudflare**: `cloudflare-cli` for domains registered with Cloudflare
- **Route53 Domains**: Can register domains directly via AWS CLI

## Important Notes

⚠️ **Never destroy this infrastructure** unless you're completely done with the project. The hosted zone nameservers will change if recreated, breaking your domain configuration.

💡 **Separate from environment infrastructure** - This bootstrap layer is shared across all environments (dev, staging, prod).

🔒 **domain.auto.tfvars is gitignored** - Each user needs to create their own with their domain name.

## Troubleshooting

**Issue**: `terraform apply` fails with "domain already exists"
**Solution**: Another AWS account may have a hosted zone for this domain. Domains can only have one Route53 hosted zone per AWS account.

**Issue**: SSL certificates fail to validate
**Solution**: Ensure nameservers are properly configured and DNS has propagated. Check with `dig NS your-domain.com`.

**Issue**: Can't find nameservers
**Solution**: Run `terraform output hosted_zone_name_servers` in this directory.
