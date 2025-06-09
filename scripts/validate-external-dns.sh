#!/bin/bash

# External DNS Validation Script
# This script validates that External DNS is working correctly

set -e

DOMAIN="${1:-example.com}"
ENVIRONMENT="${2:-dev}"
NAMESPACE="${3:-kube-system}"

echo "🔍 Validating External DNS for domain: ${DOMAIN} in environment: ${ENVIRONMENT}"

# Check if External DNS deployment exists and is ready
echo "📦 Checking External DNS deployment..."
kubectl get deployment external-dns -n ${NAMESPACE} || {
    echo "❌ External DNS deployment not found in namespace ${NAMESPACE}"
    exit 1
}

# Check deployment status
READY=$(kubectl get deployment external-dns -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment external-dns -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')

if [ "${READY}" != "${DESIRED}" ]; then
    echo "❌ External DNS deployment not ready. Ready: ${READY}, Desired: ${DESIRED}"
    kubectl describe deployment external-dns -n ${NAMESPACE}
    exit 1
fi

echo "✅ External DNS deployment is ready (${READY}/${DESIRED})"

# Check service account and IRSA annotations
echo "🔐 Checking External DNS service account..."
SA_ROLE=$(kubectl get sa external-dns -n ${NAMESPACE} -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}')

if [ -z "${SA_ROLE}" ]; then
    echo "❌ External DNS service account missing IRSA role annotation"
    kubectl describe sa external-dns -n ${NAMESPACE}
    exit 1
fi

echo "✅ External DNS service account has IRSA role: ${SA_ROLE}"

# Check External DNS logs for any errors
echo "📝 Checking External DNS logs for errors..."
LOG_ERRORS=$(kubectl logs -n ${NAMESPACE} deployment/external-dns --tail=50 | grep -i error | wc -l)

if [ "${LOG_ERRORS}" -gt 0 ]; then
    echo "⚠️  Found ${LOG_ERRORS} error(s) in External DNS logs:"
    kubectl logs -n ${NAMESPACE} deployment/external-dns --tail=20 | grep -i error
else
    echo "✅ No errors found in External DNS logs"
fi

# Check if External DNS can read Route53 hosted zones
echo "🌐 Checking Route53 permissions..."
kubectl logs -n ${NAMESPACE} deployment/external-dns --tail=100 | grep -q "Loaded zone" && {
    echo "✅ External DNS successfully loaded Route53 zones"
} || {
    echo "⚠️  External DNS may not have loaded Route53 zones yet. Check logs:"
    kubectl logs -n ${NAMESPACE} deployment/external-dns --tail=10
}

# Test DNS record creation with a sample service
echo "🧪 Testing DNS record creation..."

# Create test service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-dns-test
  namespace: default
  annotations:
    external-dns.alpha.kubernetes.io/hostname: test.${ENVIRONMENT}.${DOMAIN}
    external-dns.alpha.kubernetes.io/ttl: "60"
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: external-dns-test
EOF

echo "✅ Created test service with hostname: test.${ENVIRONMENT}.${DOMAIN}"

# Wait for External DNS to process the service
echo "⏳ Waiting 30 seconds for External DNS to create DNS record..."
sleep 30

# Check if DNS record was created
if dig +short test.${ENVIRONMENT}.${DOMAIN} | grep -q .; then
    echo "✅ DNS record created successfully for test.${ENVIRONMENT}.${DOMAIN}"
    echo "🎯 Record value: $(dig +short test.${ENVIRONMENT}.${DOMAIN})"
else
    echo "⚠️  DNS record not found for test.${ENVIRONMENT}.${DOMAIN}"
    echo "   This might be due to DNS propagation delay or External DNS configuration issues"
fi

# Check TXT record for ownership
if dig +short TXT external-dns-test.${ENVIRONMENT}.${DOMAIN} | grep -q "heritage=external-dns"; then
    echo "✅ External DNS ownership TXT record found"
else
    echo "⚠️  External DNS ownership TXT record not found"
fi

# Clean up test service
echo "🧹 Cleaning up test service..."
kubectl delete service external-dns-test -n default --ignore-not-found=true

echo ""
echo "🎉 External DNS validation completed!"
echo ""
echo "💡 To manually verify External DNS:"
echo "   kubectl logs -n ${NAMESPACE} deployment/external-dns -f"
echo "   dig test.${ENVIRONMENT}.${DOMAIN}"
echo "   aws route53 list-resource-record-sets --hosted-zone-id \$HOSTED_ZONE_ID"
