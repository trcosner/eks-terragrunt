# Kubernetes Add-ons Terraform Module

Installs and manages essential Kubernetes add-ons for EKS clusters using Helm charts.

## Features

- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **AWS Load Balancer Controller**: Provisions AWS ALB/NLB for Kubernetes Ingress resources
- **IRSA Integration**: IAM roles for service accounts using OIDC provider  
- **Helm Management**: Reliable add-on deployment and lifecycle management
- **Extensible Design**: Easy addition of new add-ons and tools

## Module Structure

- `1-cluster-autoscaler.tf`: IAM role, policy, and Helm chart for Cluster Autoscaler
- `4-aws-load-balancer-controller.tf`: IAM role, policy, and Helm chart for AWS Load Balancer Controller
- `2-variables.tf`: Input parameters
- `3-outputs.tf`: Service account ARNs and status

## Current Add-ons

### Cluster Autoscaler
- **Purpose**: Automatically scales worker nodes based on pod scheduling
- **Implementation**: Helm chart with IRSA-enabled service account
- **Permissions**: EC2 Auto Scaling Groups and instance management

### AWS Load Balancer Controller
- **Purpose**: Provisions AWS Application Load Balancers and Network Load Balancers
- **Implementation**: Helm chart with IRSA-enabled service account
- **Permissions**: ELB, EC2, and IAM service-linked role management
- **Features**: Multi-AZ load balancing, SSL termination, WAF integration

### External DNS
- **Purpose**: Automatically creates and manages Route53 DNS records for Kubernetes services
- **Implementation**: Helm chart with IRSA-enabled service account
- **Permissions**: Route53 hosted zone management and record creation
- **Features**: Service and ingress annotation-based DNS record creation

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
| `aws_load_balancer_controller_status` | Status of AWS Load Balancer Controller (enabled/disabled) |
| `aws_load_balancer_controller_version` | Version of deployed Helm chart |
| `external_dns_status` | Status of External DNS (enabled/disabled) |
| `external_dns_version` | Version of deployed Helm chart |
| `external_dns_domain` | Domain name managed by External DNS |
| `ssl_certificate_arn` | ARN of the SSL/TLS certificate for HTTPS ingress |

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

# Check cluster nodes
kubectl get nodes

# View node autoscaling events
kubectl get events --field-selector reason=TriggeredScaleUp
kubectl get events --field-selector reason=ScaleDown
```

## External DNS Configuration

### Purpose and Features

External DNS automatically creates and manages Route53 DNS records for Kubernetes services and ingresses:

- **Automatic DNS Management**: Creates A/CNAME records for services with LoadBalancer type
- **Ingress Integration**: Manages DNS for ingress resources with hostnames
- **Domain Filtering**: Restricts DNS management to specified domains
- **TXT Record Ownership**: Uses TXT records to track ownership and prevent conflicts

### Configuration

```hcl
module "kubernetes_addons" {
  source = "./infrastructure-modules/kubernetes-addons"
  
  # ... other configuration ...
  
  # External DNS
  enable_external_dns = true
  external_dns_version = "1.14.3"
  external_dns_policy_arn = dependency.bootstrap.outputs.external_dns_policy_arn
  domain_name = "example.com"
  hosted_zone_id = "Z1234567890ABC"
}
```

### Service Annotations

To create DNS records for LoadBalancer services:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.dev.example.com
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

### Ingress Integration

External DNS automatically manages DNS for ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - host: api.dev.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### Verify External DNS

```bash
# Check External DNS deployment
kubectl get deployment external-dns -n kube-system

# View External DNS logs
kubectl logs -n kube-system deployment/external-dns --tail=50 -f

# Check TXT records created by External DNS
dig TXT external-dns-app.dev.example.com

# Verify A record creation
dig app.dev.example.com
```
