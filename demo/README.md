# Demo Applications

Sample Kubernetes applications for testing EKS cluster functionality.

## Applications

### Production Nginx (`deployment.yaml`)
- **Replicas**: 4 pods
- **Resources**: 500m CPU, 512Mi memory per pod
- **Purpose**: Basic cluster functionality testing

### Autoscaler Test (`autoscaler-test.yaml`)
- **Replicas**: 8 pods (high resource usage)
- **Resources**: 750m CPU, 768Mi memory per pod
- **Purpose**: Trigger cluster autoscaler scale-up/down events

## Usage

### Deploy nginx
```bash
kubectl apply -f demo/deployment.yaml
kubectl get pods -l app=nginx
kubectl delete -f demo/deployment.yaml
```

### Test cluster autoscaler
```bash
kubectl apply -f demo/autoscaler-test.yaml
kubectl get pods -l app=autoscaler-test -w
kubectl get nodes -w

# Scale down
kubectl scale deployment autoscaler-test --replicas=2
kubectl delete -f demo/autoscaler-test.yaml
```

## Monitoring

```bash
# Check deployment status
kubectl get deployment <name>
kubectl logs -l app=<name>

# Monitor autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler -f
```
