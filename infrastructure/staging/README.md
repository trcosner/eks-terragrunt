# Staging Environment Configuration

Production-like environment configuration for testing and validation before production deployment.

## Directory Structure

```
infrastructure/staging/
├── env.hcl                 # Environment variables
├── vpc/                    # VPC and networking
├── eks/                    # EKS cluster
└── kubernetes-addons/      # Cluster add-ons
```

## Infrastructure Components

### 1. VPC
- **Network**: Multi-AZ setup with private/public subnets
- **Availability Zones**: us-east-1a, us-east-1b
- **Dependencies**: None (foundational layer)

### 2. EKS Cluster  
- **Name**: staging-demo
- **Version**: 1.33
- **Nodes**: t3a.xlarge instances (1-5 scaling)
- **Dependencies**: VPC subnets

### 3. Kubernetes Add-ons
- **Cluster Autoscaler**: Enabled with Helm chart
- **AWS Load Balancer Controller**: Enabled for ALB/NLB provisioning
- **Dependencies**: EKS cluster and OIDC provider, VPC for subnet discovery

## Deployment

Deploy in order due to dependencies:

```bash
cd infrastructure/staging
terragrunt run-all apply
```

### Individual Component Deployment

```bash
# 1. Deploy VPC first
cd infrastructure/staging/vpc
terragrunt apply

# 2. Deploy EKS cluster
cd ../eks
terragrunt apply

# 3. Deploy Kubernetes add-ons
cd ../kubernetes-addons
terragrunt apply
```

## Configuration

### Environment Settings

```hcl
# env.hcl
locals {
  env = "staging"
}
```

### EKS Configuration

- **Cluster Name**: staging-demo
- **Node Groups**: t3a.xlarge instances
- **Scaling**: 1-5 nodes
- **Capacity**: ON_DEMAND

### Validation

```bash
# Configure kubectl
aws eks update-kubeconfig --name staging-demo --region us-east-1

# Check cluster status
kubectl get nodes

# Verify add-ons
kubectl get pods -n kube-system | grep -E "(autoscaler|aws-load-balancer-controller)"

# Test applications
kubectl apply -f demo/deployment.yaml
kubectl apply -f demo/ingress-example.yaml
```

## Testing

This environment is designed for:

- **Integration Testing**: Full application stack testing
- **Load Balancer Testing**: ALB/NLB configuration validation
- **Performance Testing**: Resource scaling and autoscaling
- **Security Testing**: Network policies and access controls
- **Deployment Testing**: CI/CD pipeline validation

## Monitoring

- **CloudWatch**: Cluster and node metrics
- **EKS Logs**: Control plane logging enabled
- **Autoscaler Logs**: Scaling decision tracking
- **Load Balancer Logs**: Access logs for ALB/NLB

## Cleanup

```bash
# Destroy all components
cd infrastructure/staging
terragrunt destroy --all

# Or destroy individually in reverse order
cd kubernetes-addons && terragrunt destroy
cd ../eks && terragrunt destroy
cd ../vpc && terragrunt destroy
```

## Differences from Development

- **Stability**: More stable configurations for testing
- **Scaling**: Higher resource limits for load testing
- **Monitoring**: Enhanced logging and metrics collection
- **Security**: Production-like security configurations
- **Networking**: Production subnet sizing and configuration
