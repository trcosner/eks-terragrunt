# Kubernetes Add-ons Terraform Module

Installs and manages essential Kubernetes add-ons for EKS clusters using Helm charts.

## Features

- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **IRSA Integration**: IAM roles for service accounts using OIDC provider  
- **Helm Management**: Reliable add-on deployment and lifecycle management
- **Extensible Design**: Easy addition of new add-ons and tools

## Module Structure

- `1-cluster-autoscaler.tf`: IAM role, policy, and Helm chart
- `2-variables.tf`: Input parameters
- `3-outputs.tf`: Service account ARNs and status

## Current Add-ons

### Cluster Autoscaler
- **Purpose**: Automatically scales worker nodes based on pod scheduling
- **Implementation**: Helm chart with IRSA-enabled service account
- **Permissions**: EC2 Auto Scaling Groups and instance management

## Dependencies

Requires EKS module outputs: cluster name and OIDC provider ARN.

**Features**:
- **Auto Scaling**: Scales nodes up when pods cannot be scheduled
- **Cost Optimization**: Removes underutilized nodes to reduce costs
- **Multi-AZ Support**: Works across all availability zones
- **Configurable Behavior**: Customizable scaling policies and timers

**IAM Permissions**:
- Auto Scaling Group management
- EC2 instance lifecycle operations
- CloudWatch metrics access
- EKS cluster information

## Usage

### Basic Usage
```hcl
module "kubernetes_addons" {
  source = "./infrastructure-modules/kubernetes-addons"
  
  env                      = "dev"
  eks_name                = "demo"
  openid_provider_arn     = "arn:aws:iam::123456789012:oidc-provider/example"
  enable_cluster_autoscaler = true
  helm_chart_version      = "9.28.0"
}
```

### With Terragrunt
```hcl
terraform {
  source = "../../../infrastructure-modules/kubernetes-addons"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    eks_name = "demo"
    openid_connect_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example"
  }
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file(find_in_parent_folders("_envcommon/helm_provider.tf"))
}

inputs = {
  env = local.env
  eks_name = dependency.eks.outputs.eks_name
  openid_provider_arn = dependency.eks.outputs.openid_connect_provider_arn
  enable_cluster_autoscaler = true
  helm_chart_version = "9.28.0"
}
```

### Disable Cluster Autoscaler
```hcl
module "kubernetes_addons" {
  source = "./infrastructure-modules/kubernetes-addons"
  
  env                      = "dev"
  eks_name                = "demo"
  openid_provider_arn     = var.openid_provider_arn
  enable_cluster_autoscaler = false
  helm_chart_version      = "9.28.0"
}
```

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `env` | Environment name | `string` | - | Yes |
| `eks_name` | Name of the EKS cluster | `string` | - | Yes |
| `openid_provider_arn` | ARN of the OIDC provider for EKS | `string` | - | Yes |
| `enable_cluster_autoscaler` | Enable Cluster Autoscaler deployment | `bool` | `true` | No |
| `helm_chart_version` | Version of the Cluster Autoscaler Helm chart | `string` | - | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_autoscaler_status` | Status of Cluster Autoscaler (enabled/disabled) |
| `cluster_autoscaler_version` | Version of deployed Helm chart |

## Cluster Autoscaler Configuration

### Default Settings

The module configures the Cluster Autoscaler with production-optimized settings:

```yaml
# Scaling behavior
scale-down-delay-after-add: 2m      # Wait time after adding nodes
scale-down-unneeded-time: 2m        # Time before removing unneeded nodes
skip-nodes-with-system-pods: false  # Allow scaling nodes with system pods

# Discovery
autoDiscovery.clusterName: <eks-name>  # Automatic node group discovery
awsRegion: us-east-1                   # AWS region for API calls
```

### IAM Permissions

The Cluster Autoscaler IAM role includes these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

### Service Account Configuration

The Cluster Autoscaler service account is configured with IRSA:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/CLUSTER-cluster-autoscaler
```

## Operations and Monitoring

### Verify Installation
```bash
# Check Cluster Autoscaler deployment
kubectl get deployment cluster-autoscaler -n kube-system

# View service account
kubectl describe sa cluster-autoscaler -n kube-system

# Check IAM role annotation
kubectl get sa cluster-autoscaler -n kube-system -o yaml
```

### Monitor Scaling Activity
```bash
# View autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50 -f

# Check scaling events
kubectl get events --sort-by=.metadata.creationTimestamp | grep -i scale

# Monitor node status
kubectl get nodes -o wide

# Check pod resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Scaling Behavior Analysis
```bash
# View autoscaler status
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# Check node labels and taints
kubectl describe nodes

# View node group auto scaling activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name>
```

## Troubleshooting

### Common Issues

#### Autoscaler Not Scaling Up
**Symptoms**: Pods remain in Pending state despite resource availability
**Solutions**:
```bash
# Check autoscaler logs for errors
kubectl logs -n kube-system deployment/cluster-autoscaler

# Verify IAM permissions
aws sts get-caller-identity
kubectl describe sa cluster-autoscaler -n kube-system

# Check node group limits
aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup>

# Verify pod resource requests
kubectl describe pod <pending-pod-name>
```

#### Autoscaler Not Scaling Down
**Symptoms**: Underutilized nodes remain in cluster
**Solutions**:
```bash
# Check for pods preventing scale-down
kubectl get pods --all-namespaces -o wide

# Look for local storage or DaemonSets
kubectl describe node <node-name>

# Check autoscaler configuration
kubectl get deployment cluster-autoscaler -n kube-system -o yaml

# Review scale-down logs
kubectl logs -n kube-system deployment/cluster-autoscaler | grep -i scale-down
```

#### IRSA Authentication Issues
**Symptoms**: Autoscaler cannot access AWS APIs
**Solutions**:
```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check IAM role trust policy
aws iam get-role --role-name <cluster>-cluster-autoscaler

# Validate service account annotations
kubectl describe sa cluster-autoscaler -n kube-system

# Test AWS API access from pod
kubectl exec -n kube-system deployment/cluster-autoscaler -- aws sts get-caller-identity
```

### Debug Commands
```bash
# Describe autoscaler deployment
kubectl describe deployment cluster-autoscaler -n kube-system

# Check Helm release status
helm list -n kube-system

# View Helm chart values
helm get values cluster-autoscaler -n kube-system

# Check for resource conflicts
kubectl get all -n kube-system | grep autoscaler
```

## Customization

### Custom Autoscaler Configuration
```hcl
# Add custom Helm values in the module
locals {
  autoscaler_values = {
    "extraArgs.scale-down-delay-after-add"    = "5m"
    "extraArgs.scale-down-unneeded-time"      = "10m"
    "extraArgs.scale-down-utilization-threshold" = "0.5"
    "extraArgs.max-node-provision-time"       = "15m"
  }
}

resource "helm_release" "cluster_autoscaler" {
  # ... existing configuration ...
  
  dynamic "set" {
    for_each = local.autoscaler_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
```

### Resource Limits and Requests
```hcl
# Configure autoscaler resource allocation
resource "helm_release" "cluster_autoscaler" {
  # ... existing configuration ...
  
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  
  set {
    name  = "resources.requests.memory"
    value = "300Mi"
  }
  
  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }
  
  set {
    name  = "resources.limits.memory"
    value = "300Mi"
  }
}
```

## Future Add-ons

The module is designed to be extended with additional add-ons:

### AWS Load Balancer Controller
```hcl
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  # ... configuration ...
}
```

### External DNS
```hcl
variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = false
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0
  # ... configuration ...
}
```

### Cert Manager
```hcl
variable "enable_cert_manager" {
  description = "Enable Cert Manager"
  type        = bool
  default     = false
}

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  # ... configuration ...
}
```

## Performance Tuning

### Autoscaler Performance
```yaml
# Fast scaling for development
extraArgs:
  scale-down-delay-after-add: 30s
  scale-down-unneeded-time: 30s
  scan-interval: 5s

# Conservative scaling for production
extraArgs:
  scale-down-delay-after-add: 10m
  scale-down-unneeded-time: 10m
  scale-down-utilization-threshold: 0.5
```

### Resource Optimization
```yaml
# Ensure autoscaler has sufficient resources
resources:
  requests:
    cpu: 100m
    memory: 300Mi
  limits:
    cpu: 100m
    memory: 300Mi
```

## Security Considerations

### IRSA Security
- **Principle of Least Privilege**: IAM role has only required permissions
- **No Long-lived Credentials**: Uses temporary tokens via OIDC
- **Audit Trail**: All AWS API calls logged in CloudTrail

### Network Security
- **Pod Security Context**: Runs with non-root user
- **Security Groups**: Inherits cluster security group rules
- **Network Policies**: Compatible with network policy implementations

### Helm Security
- **Chart Verification**: Use official Kubernetes charts from trusted repositories
- **Value Validation**: Validate input values before deployment
- **Update Management**: Regular updates for security patches

## Best Practices

### 1. **Monitoring**
- Enable comprehensive logging for all add-ons
- Monitor resource usage and scaling events
- Set up alerts for failed scaling operations

### 2. **Configuration Management**
- Use consistent naming conventions
- Document all configuration changes
- Test changes in development environment first

### 3. **Security**
- Regular security scans of deployed charts
- Keep Helm charts updated
- Monitor IRSA usage and permissions

### 4. **Operations**
- Automate add-on deployment in CI/CD pipelines
- Plan for add-on upgrade procedures
- Implement rollback procedures for failed deployments

## Version Requirements

- **Terraform**: >= 0.14
- **AWS Provider**: ~> 5.0
- **Helm Provider**: ~> 2.0
- **Kubernetes**: 1.31+ (for compatibility)

## Related Documentation

- [Infrastructure Modules README](../README.md) - Module architecture overview
- [EKS Module](../eks/README.md) - EKS cluster configuration
- [Dev Kubernetes Add-ons](../../infrastructure/dev/kubernetes-addons/README.md) - Usage example
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) - Official documentation
- [Helm Documentation](https://helm.sh/docs/) - Helm package manager
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) - AWS documentation
