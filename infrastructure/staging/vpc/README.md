# VPC Configuration - Staging Environment

Terragrunt configuration for the Virtual Private Cloud infrastructure in the staging environment, providing production-like networking for pre-production testing.

## Configuration

**Module Source**: `../../../infrastructure-modules/vpc`
**Environment**: staging

### Network Architecture
- **Availability Zones**: us-east-1a, us-east-1b
- **Private Subnets**: 10.1.0.0/19, 10.1.32.0/19 (EKS worker nodes)
- **Public Subnets**: 10.1.64.0/19, 10.1.96.0/19 (NAT gateways, external LBs)
- **VPC CIDR**: 10.1.0.0/16 (isolated from dev environment)

## Environment Isolation

### Network Separation
The staging environment uses a separate VPC CIDR block (`10.1.0.0/16`) to provide complete network isolation from the development environment (`10.0.0.0/16`). This ensures:

- **No Network Overlap**: Prevents IP address conflicts
- **Independent Routing**: Separate route tables and gateways
- **Security Isolation**: Independent security groups and NACLs
- **Testing Isolation**: Network-level separation for realistic testing

### Staging-Specific Configuration
```hcl
vpc_cidr_block = "10.1.0.0/16"
private_subnets = ["10.1.0.0/19", "10.1.32.0/19"]
public_subnets = ["10.1.64.0/19", "10.1.96.0/19"]
```

## Kubernetes Integration

### EKS Cluster Tagging
Subnets are properly tagged for EKS cluster integration and load balancer discovery:

#### Private Subnet Tags
```hcl
private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "kubernetes.io/cluster/staging-demo" = "owned"
}
```

**Purpose**:
- `kubernetes.io/role/internal-elb`: Enables automatic subnet discovery for internal load balancers
- `kubernetes.io/cluster/staging-demo`: Marks subnet ownership by the staging-demo EKS cluster

#### Public Subnet Tags
```hcl
public_subnet_tags = {
  "kubernetes.io/role/elb" = "1" 
  "kubernetes.io/cluster/staging-demo" = "owned"
}
```

**Purpose**:
- `kubernetes.io/role/elb`: Enables automatic subnet discovery for external load balancers
- `kubernetes.io/cluster/staging-demo`: Marks subnet ownership by the staging-demo EKS cluster

## Production-Like Features

### High Availability
- **Multi-AZ Deployment**: Resources distributed across multiple availability zones
- **Redundant NAT Gateways**: One NAT gateway per AZ for failover capability
- **Independent Route Tables**: Separate routing for each availability zone

### Security Features
- **Private Subnets**: EKS worker nodes isolated from direct internet access
- **Public Subnets**: Only load balancers and NAT gateways in public subnets
- **Flow Logs**: VPC flow logs enabled for network monitoring
- **Security Groups**: Default security groups with restrictive rules

## Deployment

### Deploy VPC Infrastructure
```bash
cd infrastructure/staging/vpc
terragrunt apply
```

### Verify Deployment
```bash
# Check VPC details
terragrunt output vpc_id
terragrunt output private_subnets
terragrunt output public_subnets

# Verify in AWS Console or CLI
aws ec2 describe-vpcs --vpc-ids $(terragrunt output -raw vpc_id)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)"
```

## Dependencies

### Prerequisites
- **Bootstrap Infrastructure**: Must be deployed first for remote state storage
- **No Other Dependencies**: VPC is the foundational layer for staging environment

### Dependent Services
The following services depend on this VPC configuration:

1. **EKS Cluster**: Requires private subnet IDs for worker node placement
2. **Load Balancers**: Use public subnets for internet-facing load balancers
3. **RDS Databases**: Would use private subnets (if deployed)
4. **ElastiCache**: Would use private subnets (if deployed)

## Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `vpc_id` | VPC identifier | EKS cluster, security groups |
| `private_subnets` | Private subnet IDs | EKS worker nodes, private resources |
| `public_subnets` | Public subnet IDs | Load balancers, NAT gateways |
| `internet_gateway_id` | Internet Gateway ID | Route table configurations |
| `nat_gateway_ids` | NAT Gateway IDs | Monitoring and troubleshooting |

## Network Monitoring

### VPC Flow Logs
Enable VPC flow logs for network monitoring and troubleshooting:

```bash
# Enable VPC flow logs (if not already enabled)
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids $(terragrunt output -raw vpc_id) \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs/staging
```

### Network Monitoring Commands
```bash
# Check VPC status
aws ec2 describe-vpcs --vpc-ids $(terragrunt output -raw vpc_id)

# Check subnet availability
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,State]' \
  --output table

# Check NAT Gateway status
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)"

# Check route tables
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)"
```

## Security Configuration

### Network ACLs
Default network ACLs allow all traffic. For enhanced security, consider custom NACLs:

```hcl
# Example: Restrictive private subnet NACL
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.1.0.0/16"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.1.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "staging-private-nacl"
    Environment = "staging"
  }
}
```

### Security Groups
VPC provides the foundation for security group rules:

```bash
# List security groups in VPC
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)"
```

## Cost Optimization

### Staging Cost Considerations
- **NAT Gateway Costs**: ~$45/month per NAT Gateway (2 for HA)
- **Data Transfer**: Charges for data processed by NAT Gateway
- **VPC Endpoints**: Consider for AWS service access to reduce NAT costs

### Cost Monitoring
```bash
# Monitor NAT Gateway costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://nat-gateway-filter.json
```

### Cost Optimization Strategies
1. **Single NAT Gateway**: For cost savings in staging (reduces HA)
2. **VPC Endpoints**: For S3, ECR, and other AWS services
3. **Instance Types**: Right-size instances for staging workloads
4. **Scheduled Shutdowns**: Consider automated shutdown for non-24/7 testing

## Testing and Validation

### Network Connectivity Testing
```bash
# Test internet connectivity from private subnet (via NAT)
aws ssm start-session --target i-1234567890abcdef0 --document-name AWS-StartInteractiveCommand --parameters command="curl -I http://www.google.com"

# Test internal connectivity
ping 10.1.0.10  # Private IP within VPC

# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local
```

### Load Balancer Testing
```bash
# Deploy test load balancer
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: staging-test-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: test-app
EOF

# Verify load balancer subnet placement
aws elbv2 describe-load-balancers \
  --names $(kubectl get svc staging-test-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | cut -d'-' -f1)
```

## Troubleshooting

### Common Issues

#### NAT Gateway Connectivity Issues
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]'

# Check route table associations
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$(terragrunt output -raw vpc_id)" \
  --query 'RouteTables[*].[RouteTableId,Associations[*].SubnetId,Routes[*].[DestinationCidrBlock,GatewayId]]'
```

#### Subnet Tagging Issues
```bash
# Verify EKS subnet tags
aws ec2 describe-subnets \
  --subnet-ids $(terragrunt output -raw private_subnets | tr -d '[]"' | tr ',' ' ') \
  --query 'Subnets[*].[SubnetId,Tags[?Key==`kubernetes.io/cluster/staging-demo`].Value]'
```

#### DNS Resolution Issues
```bash
# Check VPC DNS settings
aws ec2 describe-vpc-attribute --vpc-id $(terragrunt output -raw vpc_id) --attribute enableDnsHostnames
aws ec2 describe-vpc-attribute --vpc-id $(terragrunt output -raw vpc_id) --attribute enableDnsSupport
```

### Recovery Procedures
```bash
# Force subnet recreation (if needed)
terragrunt apply -replace="module.vpc.aws_subnet.private[0]"

# Recreate NAT Gateway (if needed)
terragrunt apply -replace="module.vpc.aws_nat_gateway.this[0]"
```

## Environment Comparison

| Aspect | Development | Staging |
|--------|-------------|---------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Purpose** | Development testing | Pre-production validation |
| **Availability** | Best effort | High availability (multi-AZ) |
| **Cost Optimization** | Single NAT Gateway | Redundant NAT Gateways |
| **Monitoring** | Basic | Enhanced monitoring |
| **Security** | Standard | Production-equivalent |

## Related Documentation

- [VPC Module](../../../infrastructure-modules/vpc/README.md) - Module documentation and features
- [Staging Environment README](../README.md) - Staging environment overview
- [Dev VPC Configuration](../../dev/vpc/README.md) - Development VPC comparison
- [EKS Configuration](../eks/README.md) - EKS cluster that uses this VPC
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/) - Official AWS VPC documentation
