# VPC Terraform Module

Creates a VPC with public and private subnets across multiple availability zones, optimized for EKS clusters.

## Architecture

- **Multi-AZ**: High availability across us-east-1a and us-east-1b
- **Public Subnets**: Internet Gateway, NAT Gateways, external load balancers
- **Private Subnets**: EKS nodes, internal resources (outbound via NAT)
- **IP Addressing**: /19 subnets (~8,000 IPs each)

## EKS Integration

- Automatic subnet discovery via Kubernetes tags
- Load balancer controller support
- Cluster ownership tags for resource management

## Module Structure

- `1-vpc.tf`: Main VPC resource
- `2-igw.tf`: Internet Gateway
- `3-subnets.tf`: Public/private subnets
- `4-nat.tf`: NAT Gateways
- `5-routes.tf`: Route tables
- `6-outputs.tf`: VPC/subnet IDs
- `7-variables.tf`: Input parameters

## Usage

### Basic Usage
```hcl
module "vpc" {
  source = "./infrastructure-modules/vpc"
  
  env             = "dev"
  azs             = ["us-east-1a", "us-east-1b"]
  vpc_cidr_block  = "10.0.0.0/16"
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }
  
  public_subnet_tags = {
    "kubernetes.io/role/elb"         = "1"
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```

### With Terragrunt
```hcl
terraform {
  source = "../../../infrastructure-modules/vpc"
}

inputs = {
  env = local.env
  azs = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets = ["10.0.64.0/19", "10.0.96.0/19"]
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-demo"  = "owned"  
  }
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `env` | Environment name | `string` | - | Yes |
| `vpc_cidr_block` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | No |
| `azs` | List of availability zones | `list(string)` | - | Yes |
| `private_subnets` | List of private subnet CIDR blocks | `list(string)` | - | Yes |
| `public_subnets` | List of public subnet CIDR blocks | `list(string)` | - | Yes |
| `private_subnet_tags` | Additional tags for private subnets | `map(string)` | - | Yes |
| `public_subnet_tags` | Additional tags for public subnets | `map(string)` | - | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | The ID of the VPC |
| `private_subnets` | List of private subnet IDs |
| `public_subnets` | List of public subnet IDs |

## Network Design

### IP Address Allocation

For a typical 2-AZ deployment with 10.0.0.0/16 VPC:

| Subnet Type | AZ | CIDR | IP Range | Available IPs |
|------------|-------|------|----------|---------------|
| Private | us-east-1a | 10.0.0.0/19 | 10.0.0.1 - 10.0.31.254 | ~8,000 |
| Private | us-east-1b | 10.0.32.0/19 | 10.0.32.1 - 10.0.63.254 | ~8,000 |
| Public | us-east-1a | 10.0.64.0/19 | 10.0.64.1 - 10.0.95.254 | ~8,000 |
| Public | us-east-1b | 10.0.96.0/19 | 10.0.96.1 - 10.0.127.254 | ~8,000 |

### Subnet Sizing Rationale

- **Private Subnets (/19)**: Large enough for EKS nodes, pods, and other internal resources
- **Public Subnets (/19)**: Adequate for NAT Gateways, load balancers, and bastion hosts
- **Future Growth**: Remaining VPC space (10.0.128.0/17) available for expansion

## Kubernetes Integration

### Subnet Tagging

The module uses specific tags to enable Kubernetes service integration:

#### Private Subnet Tags
```hcl
"kubernetes.io/role/internal-elb" = "1"
"kubernetes.io/cluster/CLUSTER_NAME" = "owned"
```

**Purpose**:
- `kubernetes.io/role/internal-elb`: AWS Load Balancer Controller uses this tag to identify subnets for internal load balancers
- `kubernetes.io/cluster/CLUSTER_NAME`: Indicates cluster ownership of the subnet

#### Public Subnet Tags
```hcl
"kubernetes.io/role/elb" = "1"
"kubernetes.io/cluster/CLUSTER_NAME" = "owned"
```

**Purpose**:
- `kubernetes.io/role/elb`: AWS Load Balancer Controller uses this tag to identify subnets for internet-facing load balancers
- `kubernetes.io/cluster/CLUSTER_NAME`: Indicates cluster ownership of the subnet

### EKS Integration

The VPC is specifically designed to work with EKS clusters:
- **Worker Nodes**: Deploy to private subnets for security
- **Load Balancers**: Automatically discover appropriate subnets
- **Pod Networking**: AWS VPC CNI assigns IPs from subnet ranges
- **Service Discovery**: DNS resolution enabled within VPC

## Security Considerations

### Network Isolation
- **Private Subnets**: No direct internet access, outbound only via NAT Gateway
- **Public Subnets**: Internet access for load balancers and bastion hosts only
- **Security Groups**: Additional layer of security managed by other modules

### Best Practices Implemented
- **DNS Resolution**: Enabled for service discovery and AWS service integration
- **Multiple AZs**: High availability and fault tolerance
- **Separate Route Tables**: Independent routing for public and private subnets
- **NAT Gateway Redundancy**: NAT Gateway in each AZ for availability

## Routing Configuration

### Public Subnet Routing
- **Internet Gateway**: Direct route to 0.0.0.0/0 via IGW
- **Local Traffic**: VPC CIDR block routes locally
- **Cross-AZ**: Traffic between AZs routes through VPC

### Private Subnet Routing
- **NAT Gateway**: Default route 0.0.0.0/0 via NAT Gateway in same AZ
- **Local Traffic**: VPC CIDR block routes locally
- **No Direct Internet**: Enhanced security for internal resources

## Cost Considerations

### VPC Components Cost
- **VPC**: Free
- **Internet Gateway**: Free
- **NAT Gateway**: ~$45/month per gateway + data transfer
- **Subnets**: Free
- **Route Tables**: Free

### Cost Optimization Tips
1. **Single NAT Gateway**: For dev environments, consider single NAT Gateway (reduces HA)
2. **NAT Instances**: Alternative to NAT Gateways for lower cost (higher maintenance)
3. **VPC Endpoints**: Reduce NAT Gateway data transfer costs for AWS services

## Monitoring and Operations

### VPC Flow Logs
Enable VPC Flow Logs for network monitoring:
```bash
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs
```

### Troubleshooting Commands
```bash
# Check VPC details
aws ec2 describe-vpcs --vpc-ids vpc-xxxxxxxx

# List subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxx"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxxxx"

# Verify NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxxxxx"

# Check Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-xxxxxxxx"
```

## Common Issues and Solutions

### Insufficient IP Addresses
**Problem**: Pods failing to get IP addresses
**Solution**: 
- Increase subnet size (use /18 instead of /19)
- Add additional subnets in existing or new AZs
- Review pod density and resource allocation

### NAT Gateway Connectivity Issues
**Problem**: Private subnet resources cannot reach internet
**Solution**:
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways

# Verify route table associations
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxxxxxxx"

# Test connectivity from instance
# (requires access to instance in private subnet)
curl -I http://example.com
```

### Load Balancer Subnet Discovery
**Problem**: Load balancers not deploying to correct subnets
**Solution**:
- Verify subnet tags match cluster name exactly
- Ensure both `kubernetes.io/role/elb` and `kubernetes.io/cluster/NAME` tags are present
- Check that cluster name in tags matches EKS cluster name

## Customization Examples

### 3-AZ Deployment
```hcl
module "vpc" {
  source = "./infrastructure-modules/vpc"
  
  env = "prod"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  private_subnets = [
    "10.0.0.0/19",   # us-east-1a
    "10.0.32.0/19",  # us-east-1b
    "10.0.64.0/19"   # us-east-1c
  ]
  
  public_subnets = [
    "10.0.96.0/19",   # us-east-1a
    "10.0.128.0/19",  # us-east-1b
    "10.0.160.0/19"   # us-east-1c
  ]
  
  # ... other variables
}
```

### Different Region
```hcl
module "vpc" {
  source = "./infrastructure-modules/vpc"
  
  env = "dev"
  azs = ["us-west-2a", "us-west-2b"]
  
  # ... other variables
}
```

### Larger Subnets for High-Density Workloads
```hcl
module "vpc" {
  source = "./infrastructure-modules/vpc"
  
  env = "prod"
  vpc_cidr_block = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  
  # /18 subnets provide ~16,000 IPs each
  private_subnets = ["10.0.0.0/18", "10.0.64.0/18"]
  public_subnets  = ["10.0.128.0/18", "10.0.192.0/18"]
  
  # ... other variables
}
```

## Version Requirements

- **Terraform**: >= 0.14
- **AWS Provider**: ~> 5.0
- **AWS CLI**: >= 2.0 (for operations)

## Related Documentation

- [Infrastructure Modules README](../README.md) - Module architecture overview
- [EKS Module](../eks/README.md) - EKS cluster configuration
- [Dev VPC Configuration](../../infrastructure/dev/vpc/README.md) - Usage example
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/) - Official AWS documentation
- [Kubernetes Subnet Discovery](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/subnet_discovery/) - AWS Load Balancer Controller documentation
