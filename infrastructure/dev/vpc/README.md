# VPC Configuration - Dev Environment

Terragrunt configuration for the Virtual Private Cloud infrastructure in the development environment.

## Configuration

**Module Source**: `../../../infrastructure-modules/vpc`
**Environment**: dev

### Network Architecture
- **Availability Zones**: us-east-1a, us-east-1b
- **Private Subnets**: 10.0.0.0/19, 10.0.32.0/19 (EKS worker nodes)
- **Public Subnets**: 10.0.64.0/19, 10.0.96.0/19 (NAT gateways, external LBs)

### Kubernetes Integration
Private subnets tagged for internal load balancers, public subnets for external load balancers. Cluster ownership tags enable automatic subnet discovery.
- `kubernetes.io/role/internal-elb`: Enables automatic subnet discovery for internal load balancers
- `kubernetes.io/cluster/dev-demo`: Marks subnet ownership by the dev-demo EKS cluster

### Public Subnet Tags
```hcl
public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
  "kubernetes.io/cluster/dev-demo" = "owned"
}
```

**Purpose**:
- `kubernetes.io/role/elb`: Enables automatic subnet discovery for external load balancers
- `kubernetes.io/cluster/dev-demo`: Marks subnet ownership by the dev-demo EKS cluster

## Dependencies

### Upstream Dependencies
- **None** - VPC is the foundational layer

### Downstream Dependencies
- **EKS Cluster**: Requires private subnets for worker nodes
- **Load Balancers**: Automatically discover subnets via Kubernetes tags
- **NAT Gateways**: Deployed to public subnets for private subnet internet access

## Deployment

### Deploy VPC
```bash
cd infrastructure/dev/vpc
terragrunt apply
```

### Validate Configuration
```bash
cd infrastructure/dev/vpc
terragrunt validate
terragrunt plan
```

### Destroy VPC
```bash
cd infrastructure/dev/vpc
terragrunt destroy
```

**⚠️ Warning**: Destroying the VPC will also destroy all dependent resources (EKS cluster, load balancers, etc.)

## Outputs

The VPC module provides outputs used by dependent configurations:

- **VPC ID**: Used by security groups and other VPC-scoped resources
- **Private Subnets**: Used by EKS cluster for worker node placement
- **Public Subnets**: Used by load balancers and NAT gateways
- **Route Tables**: Used for additional routing rules if needed

## Network Security

### Default Security
- **Private Subnets**: No direct internet access (inbound/outbound)
- **Public Subnets**: Internet access via Internet Gateway
- **NAT Gateways**: Provide controlled outbound access for private subnets

### Security Groups
- Managed by the EKS module and individual service configurations
- VPC provides the network foundation but doesn't define security group rules

## Monitoring and Operations

### VPC Flow Logs
Consider enabling VPC Flow Logs for network monitoring:
```bash
# Enable flow logs (optional)
aws ec2 create-flow-logs --resource-type VPC --resource-ids vpc-xxxxxxxx --traffic-type ALL
```

### Network Troubleshooting
```bash
# Check VPC details
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-*"

# Check subnet details
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/cluster/dev-demo,Values=owned"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxxxx"
```

## Cost Considerations

### VPC Costs
- **VPC itself**: Free
- **NAT Gateways**: ~$45/month per gateway + data transfer costs
- **Internet Gateway**: Free
- **Elastic IPs**: Free when attached to running instances

### Optimization Tips
- Single NAT Gateway per AZ is sufficient for dev environments
- Consider NAT Instances for lower cost in development (higher maintenance)

## Common Issues

### Insufficient IP Addresses
- **Problem**: Pods failing to get IP addresses
- **Solution**: Ensure adequate subnet sizing for expected pod count
- **Dev Environment**: /19 subnets provide ample IPs for development workloads

### Load Balancer Subnet Discovery
- **Problem**: Load balancers not deploying to correct subnets
- **Solution**: Verify Kubernetes subnet tags are correctly applied
- **Check**: Ensure cluster name matches in both subnet tags and EKS configuration

### Cross-AZ Communication
- **Problem**: Services not accessible across availability zones
- **Solution**: Verify private subnet route tables include cross-AZ routes
- **Default**: VPC module should handle this automatically

## Customization

### Adding Availability Zones
To add more AZs, update the configuration:
```hcl
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
public_subnets = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
```

### Changing Subnet Sizes
For larger environments, consider smaller subnet masks:
```hcl
# /18 subnets provide ~16,000 IPs each
private_subnets = ["10.0.0.0/18", "10.0.64.0/18"]
public_subnets = ["10.0.128.0/18", "10.0.192.0/18"]
```

## Related Documentation

- [Infrastructure/dev README](../README.md) - Dev environment overview
- [VPC Module](../../../infrastructure-modules/vpc/README.md) - VPC module documentation
- [EKS Configuration](../eks/README.md) - EKS cluster configuration
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/) - Official AWS VPC documentation
