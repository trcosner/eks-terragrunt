# EKS Terraform Module

Creates an Amazon EKS cluster with managed node groups, IAM roles, and OIDC provider integration.

## Features

- **Managed Control Plane**: AWS-managed Kubernetes with automatic updates
- **Managed Node Groups**: Self-healing, auto-updating worker nodes  
- **OIDC Integration**: IAM roles for service accounts (IRSA) support
- **Multi-AZ Deployment**: High availability across availability zones
- **Auto Scaling**: Built-in cluster autoscaler support
- **Security**: Proper IAM roles and security groups

## Module Structure

- `1-eks.tf`: EKS cluster definition
- `2-nodes-iam.tf`: Node group IAM roles and policies
- `3-nodes.tf`: Managed node group configuration
- `4-irsa.tf`: OIDC provider for service accounts
- `5-outputs.tf`: Cluster name, endpoint, OIDC ARN
- `6-variables.tf`: Input parameters

## Dependencies

Requires VPC module outputs: private subnet IDs for node placement.
| `1-eks.tf` | EKS cluster and cluster IAM role definitions |
| `2-nodes-iam.tf` | IAM roles and policies for node groups |
| `3-nodes.tf` | Managed node group configurations |
| `4-irsa.tf` | OIDC identity provider for IRSA support |
| `5-outputs.tf` | Module output definitions |
| `6-variables.tf` | Input variable definitions |

## Usage

### Basic Usage
```hcl
module "eks" {
  source = "./infrastructure-modules/eks"
  
  env         = "dev"
  eks_name    = "demo"
  eks_version = "1.33"
  subnet_ids  = ["subnet-12345", "subnet-67890"]
  
  node_groups = {
    general = {
      capacity_type = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 1
        max_size     = 5
        min_size     = 1
      }
    }
  }
}
```

### Multi-Node Group Configuration
```hcl
module "eks" {
  source = "./infrastructure-modules/eks"
  
  env         = "prod"
  eks_name    = "production"
  eks_version = "1.33"
  subnet_ids  = var.private_subnet_ids
  
  node_groups = {
    general = {
      capacity_type = "ON_DEMAND"
      instance_types = ["t3a.large"]
      scaling_config = {
        desired_size = 2
        max_size     = 10
        min_size     = 2
      }
    }
    
    compute_optimized = {
      capacity_type = "SPOT"
      instance_types = ["c5.xlarge", "c5.2xlarge"]
      scaling_config = {
        desired_size = 0
        max_size     = 20
        min_size     = 0
      }
    }
    
    memory_optimized = {
      capacity_type = "ON_DEMAND"
      instance_types = ["r5.xlarge"]
      scaling_config = {
        desired_size = 0
        max_size     = 5
        min_size     = 0
      }
    }
  }
}
```

### With Terragrunt
```hcl
terraform {
  source = "../../../infrastructure-modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnets = ["subnet-1234", "subnet-5678"] 
  }
}

inputs = {
  eks_version = "1.33"
  env = local.env
  eks_name = "demo"
  subnet_ids = dependency.vpc.outputs.private_subnets
  
  node_groups = {
    general = {
      capacity_type = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 1
        max_size = 5
        min_size = 1
      }
    }
  }
}
```

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `env` | Environment name (e.g., dev, staging, prod) | `string` | - | Yes |
| `eks_name` | Name of the EKS cluster | `string` | - | Yes |
| `eks_version` | Kubernetes version for the EKS cluster | `string` | - | Yes |
| `subnet_ids` | List of subnet IDs for the EKS cluster | `list(string)` | - | Yes |
| `node_groups` | Map of node group configurations | `map(object)` | `{}` | No |
| `node_iam_policies` | IAM policies for node groups | `map(any)` | See defaults | No |
| `enable_irsa` | Enable OIDC provider for IRSA | `bool` | `true` | No |

### Node Groups Configuration Schema
```hcl
node_groups = {
  "<group_name>" = {
    capacity_type = "ON_DEMAND" | "SPOT"
    instance_types = ["t3.large", "t3.xlarge"]  # List of instance types
    scaling_config = {
      desired_size = number  # Initial number of nodes
      max_size     = number  # Maximum number of nodes
      min_size     = number  # Minimum number of nodes
    }
  }
}
```

### Default Node IAM Policies

The module automatically attaches these IAM policies to node groups:

1. `AmazonEKSWorkerNodePolicy` - Required for EKS worker nodes
2. `AmazonEC2ContainerRegistryReadOnly` - ECR access for pulling images
3. `AmazonEKS_CNI_Policy` - VPC CNI networking plugin permissions
4. `AmazonSSMManagedInstanceCore` - Systems Manager access for node management

## Outputs

| Output | Description |
|--------|-------------|
| `eks_name` | The name of the EKS cluster |
| `openid_connect_provider_arn` | ARN of the OIDC identity provider |

## Cluster Configuration

### Control Plane Settings
- **API Server Access**: Public endpoint enabled (can be customized)
- **Logging**: CloudWatch logging available (configure separately)
- **Encryption**: Secrets encryption using AWS KMS (configure separately)
- **Network**: Deployed across multiple subnets for high availability

### Node Group Features
- **Managed Lifecycle**: Automatic updates and patching
- **Auto Scaling**: Integration with Cluster Autoscaler
- **Instance Types**: Flexible instance type selection
- **Capacity Types**: Support for On-Demand and Spot instances
- **Launch Templates**: Automatic launch template creation and management

## Security Features

### IAM Roles for Service Accounts (IRSA)
The module creates an OIDC identity provider that enables:
- **Fine-grained Permissions**: Service accounts can assume specific IAM roles
- **No Long-lived Credentials**: Temporary credentials via STS
- **Audit Trail**: All AWS API calls logged in CloudTrail

### Network Security
- **Private Subnets**: Worker nodes deployed in private subnets
- **Security Groups**: Automatic security group creation and management
- **VPC Integration**: Full integration with VPC networking

### Cluster Security
- **Role-based Access**: Separate IAM roles for cluster and nodes
- **API Server Security**: Configurable endpoint access
- **Pod Security**: Support for Pod Security Standards

## Operations and Monitoring

### Cluster Access
After deployment, configure kubectl access:
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-demo
kubectl get nodes
kubectl get pods -A
```

### Monitoring Commands
```bash
# Check cluster status
kubectl cluster-info

# View node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### AWS CLI Operations
```bash
# Describe cluster
aws eks describe-cluster --name dev-demo

# List node groups
aws eks list-nodegroups --cluster-name dev-demo

# Describe node group
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general

# Check OIDC provider
aws iam list-open-id-connect-providers
```

## Scaling and Performance

### Node Group Scaling
```bash
# Manual scaling via AWS CLI
aws eks update-nodegroup-config \
  --cluster-name dev-demo \
  --nodegroup-name general \
  --scaling-config minSize=1,maxSize=10,desiredSize=3

# Check scaling activity
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general
```

### Cluster Autoscaler Integration
The module is designed to work with Cluster Autoscaler:
- Node groups support auto scaling
- Proper tags for cluster identification
- IAM permissions for scaling operations

## Cost Optimization

### Instance Type Selection
```hcl
# Cost-optimized for development
instance_types = ["t3a.medium", "t3a.large"]

# Performance-optimized for production
instance_types = ["c5.xlarge", "c5.2xlarge"]

# Memory-optimized for data processing
instance_types = ["r5.xlarge", "r5.2xlarge"]
```

### Spot Instances
```hcl
# Use spot instances for non-critical workloads
node_groups = {
  spot_workers = {
    capacity_type = "SPOT"
    instance_types = ["t3.large", "t3.xlarge", "t3a.large", "t3a.xlarge"]
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }
  }
}
```

### Cost Monitoring
```bash
# Monitor EKS costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://eks-cost-filter.json
```

## Troubleshooting

### Common Issues

#### Cluster Creation Fails
**Symptoms**: Terraform fails during cluster creation
**Solutions**:
```bash
# Check IAM permissions
aws sts get-caller-identity

# Verify subnet configuration
aws ec2 describe-subnets --subnet-ids subnet-12345

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345
```

#### Node Groups Not Joining
**Symptoms**: Nodes appear in AWS but not in kubectl
**Solutions**:
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general

# Verify IAM roles
aws iam get-role --role-name dev-demo-node-group-role

# Check node logs (requires SSH access)
journalctl -u kubelet
```

#### OIDC Provider Issues
**Symptoms**: Service accounts cannot assume IAM roles
**Solutions**:
```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check trust relationships
aws iam get-role --role-name <service-account-role>

# Validate service account annotations
kubectl describe sa <service-account-name> -n <namespace>
```

### Debugging Commands
```bash
# Check cluster configuration
kubectl config current-context
kubectl config view

# Verify node configuration
kubectl describe nodes

# Check system pod logs
kubectl logs -n kube-system deployment/coredns
kubectl logs -n kube-system daemonset/aws-node
```

## Customization Examples

### Custom Launch Template
```hcl
# Add custom user data or configuration
resource "aws_launch_template" "custom" {
  name = "${var.env}-${var.eks_name}-custom"
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    /etc/eks/bootstrap.sh ${aws_eks_cluster.this.name}
    # Custom configuration here
  EOF
  )
}
```

### Additional Security Groups
```hcl
# Add custom security group rules
resource "aws_security_group_rule" "custom" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
```

### Multiple Region Support
```hcl
# Configure for different regions
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Use region-specific availability zones
locals {
  azs = data.aws_availability_zones.available.names
}
```

## Upgrade Procedures

### Kubernetes Version Upgrade
```hcl
# Update version in configuration
eks_version = "1.34"

# Apply changes
terragrunt apply

# Update node groups (handled automatically)
```

### Node Group Updates
```bash
# Update node group configuration
aws eks update-nodegroup-config \
  --cluster-name dev-demo \
  --nodegroup-name general \
  --launch-template id=lt-12345,version=2

# Monitor update progress
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general
```

## Best Practices

### 1. **Security**
- Use private subnets for worker nodes
- Enable cluster logging
- Implement Pod Security Standards
- Regular security updates

### 2. **High Availability**
- Deploy across multiple AZs
- Use multiple node groups
- Implement proper monitoring
- Plan for disaster recovery

### 3. **Cost Management**
- Use appropriate instance types
- Implement cluster autoscaling
- Monitor resource utilization
- Consider spot instances for non-critical workloads

### 4. **Operations**
- Implement comprehensive monitoring
- Set up centralized logging
- Plan upgrade procedures
- Document operational procedures

## Version Requirements

- **Terraform**: >= 0.14
- **AWS Provider**: ~> 5.0
- **Kubernetes**: 1.31+ (EKS supported versions)

## Related Documentation

- [Infrastructure Modules README](../README.md) - Module architecture overview
- [VPC Module](../vpc/README.md) - VPC networking configuration
- [Kubernetes Add-ons Module](../kubernetes-addons/README.md) - Cluster add-ons
- [Dev EKS Configuration](../../infrastructure/dev/eks/README.md) - Usage example
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/) - Official AWS documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Official Kubernetes documentation
