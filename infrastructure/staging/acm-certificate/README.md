# ACM Certificate - Staging Environment

SSL/TLS certificate configuration for the staging environment using AWS Certificate Manager with DNS validation.

## Overview

Creates a wildcard SSL certificate for the staging environment subdomain with automatic DNS validation through Route53. This provides a production-like SSL setup for testing and validation.

## Certificate Configuration

- **Primary Domain**: `demo.staging.{domain}`
- **Wildcard SAN**: `*.staging.{domain}`
- **Validation**: DNS validation via Route53
- **Auto-Renewal**: Enabled (AWS managed)
- **Environment**: Staging

## Dependencies

This configuration depends on:

1. **Bootstrap Infrastructure**: Domain and hosted zone setup
   - Route53 hosted zone ID
   - Domain name configuration
   - DNS delegation to AWS nameservers

## Usage

### Deploy Certificate
```bash
cd infrastructure/staging/acm-certificate
terragrunt apply
```

### Check Certificate Status
```bash
# Get certificate ARN
terragrunt output certificate_arn

# Check certificate status
aws acm describe-certificate --certificate-arn $(terragrunt output -raw certificate_arn)
```

## Configuration Details

### Domain Structure
```
{domain}                          # Bootstrap managed
├── staging.{domain}             # Staging environment
│   ├── demo.staging.{domain}    # Primary certificate domain
│   ├── api.staging.{domain}     # API services (covered by wildcard)
│   ├── app.staging.{domain}     # Applications (covered by wildcard)
│   └── *.staging.{domain}       # Wildcard for any subdomain
```

### Certificate Specifications
- **Algorithm**: RSA-2048 or ECDSA P-256
- **Validation**: DNS (automatic via Route53)
- **Renewal**: Automatic (60 days before expiration)
- **Transparency**: Certificate Transparency logging enabled

## Production-Like Configuration

### Staging Environment Purpose
- **Pre-Production Testing**: Test SSL configurations before production
- **Integration Testing**: Validate certificate integration with load balancers
- **Security Testing**: Test SSL/TLS configurations and policies
- **Performance Testing**: Measure SSL handshake performance

### Certificate Differences from Dev
| Aspect | Development | Staging |
|--------|-------------|---------|
| Domain | `*.dev.{domain}` | `*.staging.{domain}` |
| Usage | Development testing | Pre-production validation |
| Monitoring | Basic | Enhanced (production-like) |
| Security | Standard | Production-equivalent |

## Validation Process

### Automatic DNS Validation
1. **Certificate Request**: Terragrunt requests certificate from ACM
2. **DNS Records**: Module automatically creates validation CNAME records
3. **Validation**: AWS validates domain ownership via DNS
4. **Issuance**: Certificate becomes available (5-30 minutes)

### Validation Verification
```bash
# Check validation records in Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terragrunt output -raw zone_id) \
  --query 'ResourceRecordSets[?Type==`CNAME` && contains(Name, `staging`)]'

# Verify DNS propagation
dig _validation-hash.staging.{domain} CNAME

# Test certificate
openssl s_client -connect demo.staging.{domain}:443 -servername demo.staging.{domain}
```

## Outputs

| Output | Description | Usage |
|--------|-------------|-------|
| `certificate_arn` | Certificate ARN for load balancers | ALB/NLB SSL configuration |
| `certificate_domain_name` | Primary domain name | Certificate identification |
| `certificate_status` | Validation status | Monitoring and troubleshooting |

## Integration with Services

### Application Load Balancer
```yaml
# Kubernetes Ingress using the certificate
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: staging-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-east-1:account:certificate/staging-cert-id"
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  tls:
  - hosts:
    - demo.staging.example.com
    - api.staging.example.com
  rules:
  - host: demo.staging.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: staging-app-service
            port:
              number: 80
```

### SSL Policy Testing
```yaml
# Test different SSL policies in staging
metadata:
  annotations:
    # Test latest SSL policy
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-Ext-2018-06
    
    # Test HTTP to HTTPS redirect
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    
    # Test security headers
    alb.ingress.kubernetes.io/target-group-attributes: |
      stickiness.enabled=true,
      stickiness.lb_cookie.duration_seconds=86400
```

## Pre-Production Testing

### SSL Configuration Testing
```bash
# Test SSL/TLS configuration
testssl.sh https://demo.staging.{domain}

# Check certificate chain
echo | openssl s_client -connect demo.staging.{domain}:443 -showcerts

# Test SSL policies
curl -I https://demo.staging.{domain} -w "%{http_code} %{ssl_verify_result}\n"
```

### Load Testing with SSL
```bash
# SSL performance testing
ab -n 1000 -c 10 https://demo.staging.{domain}/

# SSL handshake performance
curl -w "@curl-format.txt" -o /dev/null -s https://demo.staging.{domain}/
```

## Certificate Monitoring

### Enhanced Monitoring for Staging
```bash
# Set up certificate expiration alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "staging-cert-expiry" \
  --alarm-description "Staging certificate expiring soon" \
  --metric-name DaysToExpiry \
  --namespace AWS/CertificateManager \
  --statistic Average \
  --period 86400 \
  --threshold 30 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=CertificateArn,Value=$(terragrunt output -raw certificate_arn)
```

### Security Monitoring
```bash
# Monitor certificate usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$(terragrunt output -raw certificate_arn) \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S)
```

## Troubleshooting

### Staging-Specific Issues

#### Certificate Not Trusted in Browsers
```bash
# Verify certificate chain
openssl s_client -connect demo.staging.{domain}:443 -showcerts | \
  openssl x509 -noout -text

# Check certificate transparency logs
curl -s "https://crt.sh/?q=staging.{domain}&output=json" | jq '.[0]'
```

#### Load Balancer SSL Issues
```bash
# Check ALB certificate configuration
aws elbv2 describe-listeners \
  --load-balancer-arn $(kubectl get ingress staging-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | \
  xargs aws elbv2 describe-load-balancers --names | jq -r '.LoadBalancers[0].LoadBalancerArn')

# Verify SSL policy
aws elbv2 describe-ssl-policies --names ELBSecurityPolicy-TLS-1-2-2017-01
```

### Common Staging Issues
1. **Certificate mismatch**: Ensure certificate covers all staging subdomains
2. **SSL policy compatibility**: Test modern SSL policies for compatibility
3. **Performance impact**: Monitor SSL handshake performance under load

## Security Testing

### SSL/TLS Security Assessment
```bash
# Use SSLyze for comprehensive testing
sslyze demo.staging.{domain}

# Test for vulnerabilities
nmap --script ssl-enum-ciphers -p 443 demo.staging.{domain}

# Check HSTS headers
curl -I https://demo.staging.{domain} | grep -i strict
```

### Certificate Validation Testing
```bash
# Test certificate validation
openssl verify -CAfile ca-bundle.crt staging-cert.pem

# Test certificate revocation
openssl ocsp -issuer ca-cert.pem -cert staging-cert.pem -url http://ocsp.example.com
```

## Deployment Pipeline Integration

### CI/CD Certificate Validation
```yaml
# Example GitHub Actions step
- name: Validate Staging Certificate
  run: |
    CERT_ARN=$(cd infrastructure/staging/acm-certificate && terragrunt output -raw certificate_arn)
    STATUS=$(aws acm describe-certificate --certificate-arn $CERT_ARN --query 'Certificate.Status' --output text)
    if [ "$STATUS" != "ISSUED" ]; then
      echo "Certificate not ready: $STATUS"
      exit 1
    fi
```

### Automated Testing
```bash
# Certificate health check script
#!/bin/bash
DOMAIN="demo.staging.{domain}"
CERT_ARN=$(terragrunt output -raw certificate_arn)

# Check certificate status
STATUS=$(aws acm describe-certificate --certificate-arn $CERT_ARN --query 'Certificate.Status' --output text)
echo "Certificate Status: $STATUS"

# Test HTTPS connectivity
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Response: $HTTP_CODE"

# Check certificate expiration
EXPIRY=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | \
  openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
echo "Certificate Expires: $EXPIRY"
```

## Cost Information

### Staging Environment Costs
- **Certificate**: No charge for ACM certificates
- **DNS Validation**: Standard Route53 query charges
- **Load Balancer**: ALB/NLB costs for HTTPS listeners
- **Monitoring**: CloudWatch alarms and metrics

### Cost Optimization
- Share Route53 hosted zone across environments
- Use Application Load Balancer for multiple applications
- Monitor SSL handshake performance to optimize costs

## Related Documentation

- [ACM Certificate Module](../../../infrastructure-modules/acm-certificate/README.md) - Module documentation
- [Bootstrap README](../../../bootstrap/README.md) - Domain and hosted zone setup
- [Staging Environment README](../README.md) - Staging environment overview
- [Dev ACM Certificate](../../dev/acm-certificate/README.md) - Development environment certificate
- [Production SSL Best Practices](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html) - AWS SSL configuration guide
