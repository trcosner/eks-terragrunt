# Cluster Autoscaler Testing Guide

This document outlines the comprehensive testing process for verifying cluster autoscaler functionality in the EKS Terragrunt infrastructure.

## Overview

The cluster autoscaler automatically adjusts the number of nodes in your EKS cluster based on pod resource requirements. This testing guide validates both scale-up and scale-down scenarios.

## Prerequisites

- EKS clusters deployed (`dev-demo` and `staging-demo`)
- Cluster autoscaler installed via Terragrunt kubernetes-addons module
- `kubectl` CLI configured
- AWS CLI configured with appropriate permissions

## Test Environment Setup

### 1. Verify Cluster Autoscaler Status

Check that the cluster autoscaler is running in both environments:

```bash
# Function to check cluster autoscaler for a specific cluster
check_cluster_autoscaler() {
  local cluster_name=$1
  echo "=== Checking Cluster: $cluster_name ==="
  
  # Switch context
  aws eks update-kubeconfig --region us-east-1 --name $cluster_name
  
  # Check pods
  echo "Cluster Autoscaler Pods:"
  kubectl get pods -n kube-system | grep cluster-autoscaler
  
  # Check deployment
  echo "Deployment Status:"
  kubectl get deployment cluster-autoscaler-aws-cluster-autoscaler -n kube-system
  
  echo ""
}

# Check both environments
check_cluster_autoscaler "dev-demo"
check_cluster_autoscaler "staging-demo"
```

Expected output:
- Pod status: `Running`
- Deployment status: `1/1 Ready`

### 2. Baseline Cluster State

Before testing, record the current cluster state:

```bash
# Switch to target cluster (example: dev-demo)
aws eks update-kubeconfig --region us-east-1 --name dev-demo

# Check current nodes
kubectl get nodes

# Check current pods
kubectl get pods --all-namespaces
```

## Scale-Up Testing

### Test Deployment Configuration

The test uses `/demo/autoscaler-test.yaml` with the following characteristics:

- **Replicas**: 8 pods
- **Resource Requests**: 750m CPU, 768Mi memory per pod
- **Total Resources**: ~6 CPU cores, ~6GB memory
- **Anti-affinity**: Spreads pods across nodes
- **Node Selector**: Linux nodes only

### Scale-Up Test Procedure

1. **Deploy the test workload**:
   ```bash
   kubectl apply -f demo/autoscaler-test.yaml
   ```

2. **Monitor initial pod status**:
   ```bash
   kubectl get pods -l app=autoscaler-test -w
   ```
   
   Expected: Some pods `Running`, others `Pending` due to resource constraints

3. **Check cluster autoscaler logs**:
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler --tail=20
   ```
   
   Look for: Scale-up decision logs and node provisioning

4. **Monitor node scaling**:
   ```bash
   # Watch nodes being added
   kubectl get nodes -w
   ```
   
   Expected: New nodes appear within 30-60 seconds

5. **Verify pod distribution**:
   ```bash
   kubectl get pods -l app=autoscaler-test -o wide
   ```
   
   Expected: Pods distributed across multiple nodes

### Scale-Up Success Criteria

- ✅ All 8 pods reach `Running` status
- ✅ New nodes are provisioned automatically
- ✅ Pods are distributed across available nodes
- ✅ Autoscaler logs show scale-up decisions
- ✅ Total provisioning time < 2 minutes

## Scale-Down Testing

### Scale-Down Test Procedure

1. **Reduce deployment size**:
   ```bash
   kubectl scale deployment autoscaler-test --replicas=2
   ```

2. **Verify pod reduction**:
   ```bash
   kubectl get pods -l app=autoscaler-test
   ```
   
   Expected: Only 2 pods remain `Running`

3. **Check autoscaler scale-down recognition**:
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler --tail=10
   ```
   
   Look for: "unneeded" node identification and cooldown status

4. **Monitor node count over time**:
   ```bash
   # Nodes will remain for cooldown period (typically 10 minutes)
   kubectl get nodes
   ```

### Scale-Down Success Criteria

- ✅ Pod count reduces to 2 immediately
- ✅ Autoscaler identifies unused nodes
- ✅ Scale-down cooldown is respected
- ✅ Nodes marked for eventual removal

## Cleanup

Remove test deployment:
```bash
kubectl delete -f demo/autoscaler-test.yaml
```

## Production Deployment Testing

Test the existing production deployment:

```bash
# Deploy production workload
kubectl apply -f demo/deployment.yaml

# Verify deployment
kubectl get deployment nginx
kubectl get pods -l app=nginx

# Scale to test autoscaler response
kubectl scale deployment nginx --replicas=8
kubectl get pods -l app=nginx -w

# Scale back down
kubectl scale deployment nginx --replicas=4
```

## Monitoring Commands

### Real-time Monitoring

```bash
# Watch autoscaler logs in real-time
kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler -f

# Watch pod status
kubectl get pods -w

# Watch node status
kubectl get nodes -w

# Check node resource usage (requires metrics-server)
kubectl top nodes
```

### Historical Analysis

```bash
# Check autoscaler events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check autoscaler configuration
kubectl describe deployment cluster-autoscaler-aws-cluster-autoscaler -n kube-system

# Check node group configuration
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name <nodegroup-name> --region us-east-1
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**
   - Check: Resource requests vs. node capacity
   - Check: Node selectors and taints
   - Check: Autoscaler logs for errors

2. **Autoscaler not scaling up**
   - Verify: Autoscaler pod is running
   - Check: IAM permissions for autoscaler
   - Check: Node group max size limits

3. **Nodes not scaling down**
   - Normal: 10-minute cooldown period
   - Check: Pod disruption budgets
   - Check: System pods preventing drain

### Debug Commands

```bash
# Check autoscaler configuration
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# Check node group autoscaling settings
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(Tags[?Key==`kubernetes.io/cluster/dev-demo`].Value, `owned`)].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity]' --output table --region us-east-1

# Check node conditions
kubectl describe nodes

# Check pod resource usage
kubectl top pods
```

## Test Results Template

Document your test results using this template:

```markdown
## Test Results - [Date]

### Environment: [dev-demo/staging-demo]

#### Scale-Up Test
- Initial nodes: X
- Deployed replicas: 8
- Final nodes: Y
- Time to scale: X seconds
- Status: ✅ PASS / ❌ FAIL

#### Scale-Down Test
- Initial replicas: 8
- Scaled to replicas: 2
- Autoscaler recognition: ✅ YES / ❌ NO
- Cooldown respected: ✅ YES / ❌ NO
- Status: ✅ PASS / ❌ FAIL

#### Notes
- [Any observations or issues]
```

## Configuration Files

### Test Deployment Specs

- **Location**: `/demo/autoscaler-test.yaml`
- **Purpose**: Triggers autoscaler with high resource requirements
- **Features**: Anti-affinity, health checks, realistic resource requests

### Production Deployment

- **Location**: `/demo/deployment.yaml`  
- **Purpose**: Standard nginx deployment for production testing
- **Features**: Moderate resource requirements, production-ready configuration

## Integration with CI/CD

This testing process can be automated in CI/CD pipelines:

```bash
#!/bin/bash
# Automated autoscaler test script

set -e

CLUSTER_NAME=${1:-dev-demo}
echo "Testing autoscaler on cluster: $CLUSTER_NAME"

# Setup
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME

# Test scale-up
kubectl apply -f demo/autoscaler-test.yaml
sleep 60
RUNNING_PODS=$(kubectl get pods -l app=autoscaler-test --no-headers | grep -c "Running" || echo "0")

if [ "$RUNNING_PODS" -eq 8 ]; then
    echo "✅ Scale-up test PASSED"
else
    echo "❌ Scale-up test FAILED - Only $RUNNING_PODS/8 pods running"
    exit 1
fi

# Test scale-down  
kubectl scale deployment autoscaler-test --replicas=2
sleep 30
RUNNING_PODS=$(kubectl get pods -l app=autoscaler-test --no-headers | grep -c "Running" || echo "0")

if [ "$RUNNING_PODS" -eq 2 ]; then
    echo "✅ Scale-down test PASSED"
else
    echo "❌ Scale-down test FAILED - $RUNNING_PODS pods running instead of 2"
    exit 1
fi

# Cleanup
kubectl delete -f demo/autoscaler-test.yaml

echo "🎉 All autoscaler tests PASSED for $CLUSTER_NAME"
```

## Conclusion

This testing process validates that the cluster autoscaler is properly configured and functional. Regular testing ensures your EKS cluster can handle varying workload demands automatically.

For questions or issues, refer to the main project README.md or the troubleshooting section above.
