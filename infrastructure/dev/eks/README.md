# EKS Cluster Configuration - Dev Environment

Terragrunt configuration for the Amazon EKS cluster in the development environment.

## Configuration

**Module Source**: `../../../infrastructure-modules/eks`
**Cluster Name**: dev-demo
**Kubernetes Version**: 1.33

### Node Group
- **Instance Type**: t3a.xlarge (4 vCPU, 16 GB RAM)
- **Capacity**: ON_DEMAND
- **Scaling**: 1-5 nodes (desired: 1)
- **Placement**: Private subnets only

### Features
- OIDC provider enabled for IAM roles for service accounts
- Managed node groups with automatic updates
- Security groups configured for cluster communication

## Dependencies

Requires VPC outputs: private subnet IDs for node placement.
  config_path = "../vpc"
  mock_outputs = {
    private_subnets = ["subnet-1234", "subnet-5678"] 
  }
}
```

**Requirements**:
- VPC must be deployed first
- Private subnets are required for worker node placement
- Mock outputs enable validation without deployed VPC

**Inputs from VPC**:
- `subnet_ids = dependency.vpc.outputs.private_subnets`

## Security and Networking

### Network Placement
- **Worker Nodes**: Deployed in private subnets
- **Control Plane**: AWS-managed, accessible via API endpoint
- **Pod Networking**: AWS VPC CNI for native AWS networking

### Security Features
- **Node Security Groups**: Automatically managed by EKS
- **Control Plane Security**: AWS-managed encryption and access controls
- **OIDC Provider**: Enables IAM roles for service accounts (IRSA)
- **Private Endpoint**: Control plane accessible from within VPC

### IAM Integration
The cluster provides an OIDC provider ARN that enables:
- **Service Account Authentication**: Kubernetes service accounts can assume IAM roles
- **AWS Service Integration**: Pods can access AWS services with fine-grained permissions
- **Security Best Practices**: No need for long-lived AWS credentials in pods

## Deployment

### Deploy EKS Cluster
```bash
cd infrastructure/dev/eks
terragrunt apply
```

This will:
1. Create the EKS cluster control plane
2. Set up the managed node group
3. Configure security groups and networking
4. Create the OIDC identity provider
5. Configure kubectl access

### Validate Configuration
```bash
cd infrastructure/dev/eks
terragrunt validate
terragrunt plan
```

### Access the Cluster
After deployment, configure kubectl:
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-demo
kubectl get nodes
kubectl get pods -A
```

## Outputs

The EKS module provides outputs for dependent configurations:

- **`eks_name`**: Cluster name used by add-ons and applications
- **`openid_connect_provider_arn`**: OIDC provider ARN for service account authentication
- **Additional outputs**: Cluster endpoint, certificate authority, security group IDs

## Node Group Details

### Instance Selection
- **t3a.xlarge**: Cost-effective choice for development
  - 4 vCPUs: Sufficient for multiple pods
  - 16 GB RAM: Good for Java/Node.js applications
  - Network Performance: Up to 5 Gbps

### Scaling Behavior
- **Min Size (1)**: Ensures cluster availability
- **Desired Size (1)**: Starting point for cost optimization
- **Max Size (5)**: Allows scaling for load testing
- **Auto Scaling**: Managed by Cluster Autoscaler (installed via add-ons)

### Cost Optimization
```bash
# Monitor node utilization
kubectl top nodes

# Check pod resource requests/limits
kubectl describe nodes

# Scale down manually if needed
kubectl cordon <node-name>
kubectl drain <node-name>
```

## Kubernetes Version Management

### Current Version: 1.33
- Latest stable version with long-term support
- Regular security updates and bug fixes
- Compatible with most Kubernetes tools and operators

### Upgrade Process
```bash
# Update terragrunt.hcl
eks_version = "1.34"

# Apply changes
terragrunt apply

# Update nodes (handled automatically by managed node groups)
```

## Monitoring and Operations

### Cluster Health
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system
```

### CloudWatch Integration
The cluster automatically integrates with CloudWatch for:
- Control plane logs
- Node metrics
- Container insights (if enabled)

### Troubleshooting Commands
```bash
# Check EKS cluster details
aws eks describe-cluster --name dev-demo

# Check node group status
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general

# Check OIDC provider
aws iam list-open-id-connect-providers
```

## Security Considerations

### Best Practices
- **Private Nodes**: Worker nodes have no direct internet access
- **Security Groups**: Automatically configured for cluster communication
- **Encryption**: Data at rest and in transit encryption enabled
- **Network Policies**: Consider implementing Kubernetes network policies

### Access Control
- **AWS IAM**: Controls AWS API access to cluster
- **Kubernetes RBAC**: Controls in-cluster permissions
- **Pod Security**: Consider Pod Security Standards for workload security

## Cost Management

### Development Cost Optimization
```bash
# Stop cluster outside business hours (requires external tooling)
# Scale down to 0 nodes during non-use periods
kubectl patch deployment -n kube-system cluster-autoscaler -p '{"spec":{"replicas":0}}'

# Monitor costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Expected Monthly Costs (Dev Environment)
- **EKS Control Plane**: ~$72/month
- **t3a.xlarge Node**: ~$120/month (if running 24/7)
- **EBS Volumes**: ~$8/month per node
- **Data Transfer**: Variable based on usage

## Common Issues

### Node Group Not Healthy
**Symptoms**: Nodes in NotReady state
**Solutions**:
```bash
# Check node logs
kubectl describe node <node-name>

# Check AWS EKS console for node group status
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general
```

### Pods Stuck in Pending
**Symptoms**: Pods cannot be scheduled
**Solutions**:
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name>

# Verify Cluster Autoscaler is running
kubectl get pods -n kube-system | grep autoscaler
```

### kubectl Access Issues
**Symptoms**: Cannot connect to cluster
**Solutions**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --name dev-demo --region us-east-1

# Check AWS credentials
aws sts get-caller-identity

# Verify cluster exists
aws eks describe-cluster --name dev-demo
```

## Customization

### Adding Node Groups
```hcl
node_groups = {
  general = {
    # existing configuration
  }
  compute_optimized = {
    capacity_type = "SPOT"
    instance_types = ["c5.large", "c5.xlarge"]
    scaling_config = {
      desired_size = 0
      max_size = 10
      min_size = 0
    }
  }
}
```

### Changing Instance Types
```hcl
# For CPU-intensive workloads
instance_types = ["c5.xlarge", "c5.2xlarge"]

# For memory-intensive workloads
instance_types = ["r5.xlarge", "r5.2xlarge"]

# For cost optimization with spot instances
capacity_type = "SPOT"
instance_types = ["t3.large", "t3.xlarge", "t3a.large", "t3a.xlarge"]
```

## Related Documentation

- [Infrastructure/dev README](../README.md) - Dev environment overview
- [EKS Module](../../../infrastructure-modules/eks/README.md) - EKS module documentation
- [Kubernetes Add-ons](../kubernetes-addons/README.md) - Cluster add-ons configuration
- [VPC Configuration](../vpc/README.md) - Network infrastructure
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/) - Official AWS EKS documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Official Kubernetes documentation
