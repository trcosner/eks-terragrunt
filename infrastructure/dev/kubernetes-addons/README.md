# Kubernetes Add-ons - Dev Environment

Terragrunt configuration for essential Kubernetes add-ons in the development environment.

## Configuration

**Module Source**: `../../../infrastructure-modules/kubernetes-addons`
**Primary Add-on**: Cluster Autoscaler with automatic node scaling

Depends on EKS cluster configuration for cluster name and OIDC provider.

## Deployment

### Deploy Add-ons
```bash
cd infrastructure/dev/kubernetes-addons
terragrunt apply
```

This will:
1. Generate the Helm provider configuration
2. Install the Cluster Autoscaler Helm chart
3. Configure IAM roles and service accounts
4. Set up monitoring and logging

### Validate Configuration
```bash
cd infrastructure/dev/kubernetes-addons
terragrunt validate
terragrunt plan
```

### Verify Add-ons Installation
```bash
# Check Cluster Autoscaler deployment
kubectl get deployment cluster-autoscaler -n kube-system

# Check service account and IAM role binding
kubectl describe sa cluster-autoscaler -n kube-system

# View autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler
```

## Monitoring and Operations

### Cluster Autoscaler Monitoring
```bash
# Check autoscaler status
kubectl get pods -n kube-system | grep autoscaler

# View scaling events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node status
kubectl get nodes

# Monitor autoscaler decisions
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50 -f
```

### Scaling Behavior
```bash
# Trigger scale-up (create resource-intensive pod)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scale-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: scale-test
  template:
    metadata:
      labels:
        app: scale-test
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 1000m
            memory: 1Gi
EOF

# Clean up
kubectl delete deployment scale-test
```

### Autoscaler Configuration
```bash
# Check current autoscaler configuration
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# View autoscaler annotations on nodes
kubectl describe nodes | grep -A 5 -B 5 "cluster-autoscaler"
```

## Customization Options

### Adding More Add-ons
The module can be extended to include additional add-ons:

```hcl
inputs = {
  # Existing configuration
  enable_cluster_autoscaler = true
  
  # Additional add-ons (examples)
  enable_aws_load_balancer_controller = true
  enable_external_dns = true
  enable_cert_manager = true
  enable_metrics_server = true
}
```

### Cluster Autoscaler Tuning
```hcl
# Custom autoscaler configuration
cluster_autoscaler_config = {
  scale_down_delay_after_add = "10m"
  scale_down_unneeded_time = "10m"
  scale_down_utilization_threshold = 0.5
  skip_nodes_with_local_storage = false
  skip_nodes_with_system_pods = false
}
```

## Security Considerations

### IAM Roles for Service Accounts (IRSA)
- **Principle of Least Privilege**: Each add-on gets only required permissions
- **No Long-lived Credentials**: Uses temporary tokens via OIDC
- **Audit Trail**: All AWS API calls are logged in CloudTrail

### Network Security
- **Pod Security**: Add-ons run with appropriate security contexts
- **Network Policies**: Consider implementing network policies for add-on isolation
- **Service Mesh**: Compatible with service mesh implementations

## Troubleshooting

### Cluster Autoscaler Issues

#### Pods Not Scaling
**Symptoms**: Pods remain in Pending state despite autoscaler
**Solutions**:
```bash
# Check autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Verify node group limits
aws eks describe-nodegroup --cluster-name dev-demo --nodegroup-name general

# Check resource requests vs available capacity
kubectl describe nodes
```

#### Nodes Not Scaling Down
**Symptoms**: Underutilized nodes remain in cluster
**Solutions**:
```bash
# Check for pods preventing scale-down
kubectl get pods --all-namespaces -o wide

# Look for DaemonSets or local storage
kubectl describe node <node-name>

# Check autoscaler configuration
kubectl logs -n kube-system deployment/cluster-autoscaler | grep scale-down
```

### Helm Provider Issues
**Symptoms**: Terraform cannot connect to cluster
**Solutions**:
```bash
# Verify cluster access
kubectl cluster-info

# Check generated provider configuration
cat helm-provider.tf

# Re-generate provider
terragrunt init -reconfigure
```

### OIDC Provider Issues
**Symptoms**: Service accounts cannot assume IAM roles
**Solutions**:
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check service account annotations
kubectl describe sa cluster-autoscaler -n kube-system

# Verify IAM role trust policy
aws iam get-role --role-name <autoscaler-role-name>
```

## Cost Optimization

### Autoscaler Cost Benefits
- **Right-sizing**: Automatically adjusts cluster capacity to workload demands
- **Spot Integration**: Works with spot instances for additional savings
- **Scheduled Scaling**: Can be configured for predictable workload patterns

### Monitoring Costs
```bash
# Track scaling events and costs
kubectl get events --field-selector reason=TriggeredScaleUp
kubectl get events --field-selector reason=ScaleDown

# Monitor node utilization
kubectl top nodes --sort-by=cpu
kubectl top nodes --sort-by=memory
```

## Performance Tuning

### Autoscaler Response Time
```yaml
# Faster scaling for development (in Helm values)
autoscaling:
  scaleDownDelayAfterAdd: 1m
  scaleDownUnneededTime: 1m
  scaleDownUtilizationThreshold: 0.3
```

### Resource Allocation
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

## Future Add-ons

Consider adding these add-ons for enhanced functionality:

1. **AWS Load Balancer Controller**: Advanced load balancing features
2. **External DNS**: Automatic DNS record management
3. **Cert Manager**: Automatic TLS certificate management
4. **Metrics Server**: Resource usage metrics for HPA
5. **Prometheus**: Comprehensive monitoring and alerting
6. **Grafana**: Visualization and dashboards
7. **Fluent Bit**: Log aggregation and forwarding

## Related Documentation

- [Infrastructure/dev README](../README.md) - Dev environment overview
- [Kubernetes Add-ons Module](../../../infrastructure-modules/kubernetes-addons/README.md) - Module documentation
- [EKS Configuration](../eks/README.md) - EKS cluster setup
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) - Official documentation
- [Helm Documentation](https://helm.sh/docs/) - Helm package manager documentation
