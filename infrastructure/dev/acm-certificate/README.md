# ACM Certificate - Dev Environment

SSL/TLS certificate configuration for the development environment using AWS Certificate Manager with DNS validation.

## Overview

Creates a wildcard SSL certificate for the development environment subdomain with automatic DNS validation through Route53.

## Certificate Configuration

- **Primary Domain**: `demo.dev.{domain}`
- **Wildcard SAN**: `*.dev.{domain}`
- **Validation**: DNS validation via Route53
- **Auto-Renewal**: Enabled (AWS managed)
- **Environment**: Development

## Dependencies

This configuration depends on:

1. **Bootstrap Infrastructure**: Domain and hosted zone setup
   - Route53 hosted zone ID
   - Domain name configuration
   - DNS delegation to AWS nameservers

## Usage

### Deploy Certificate
```bash
cd infrastructure/dev/acm-certificate
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
├── dev.{domain}                 # Development environment
│   ├── demo.dev.{domain}        # Primary certificate domain
│   ├── api.dev.{domain}         # API services (covered by wildcard)
│   ├── app.dev.{domain}         # Applications (covered by wildcard)
│   └── *.dev.{domain}           # Wildcard for any subdomain
```

### Certificate Specifications
- **Algorithm**: RSA-2048 or ECDSA P-256
- **Validation**: DNS (automatic via Route53)
- **Renewal**: Automatic (60 days before expiration)
- **Transparency**: Certificate Transparency logging enabled

## Validation Process

### Automatic DNS Validation
1. **Certificate Request**: Terragrunt requests certificate from ACM
2. **DNS Records**: Module automatically creates validation CNAME records
3. **Validation**: AWS validates domain ownership via DNS
4. **Issuance**: Certificate becomes available (5-30 minutes)

### Manual Verification
```bash
# Check validation records in Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terragrunt output -raw zone_id) \
  --query 'ResourceRecordSets[?Type==`CNAME`]'

# Verify DNS propagation
dig _validation-hash.dev.{domain} CNAME

# Test certificate
openssl s_client -connect demo.dev.{domain}:443 -servername demo.dev.{domain}
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
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-east-1:account:certificate/cert-id"
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
spec:
  tls:
  - hosts:
    - demo.dev.example.com
  rules:
  - host: demo.dev.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### Network Load Balancer
```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = dependency.acm_certificate.outputs.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

## Certificate Monitoring

### CloudWatch Metrics
```bash
# Monitor certificate expiration
aws cloudwatch get-metric-statistics \
  --namespace AWS/CertificateManager \
  --metric-name DaysToExpiry \
  --dimensions Name=CertificateArn,Value=$(terragrunt output -raw certificate_arn) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average
```

### Certificate Health Check
```bash
# Test certificate from outside AWS
curl -I https://demo.dev.{domain}

# Check certificate details
echo | openssl s_client -connect demo.dev.{domain}:443 -servername demo.dev.{domain} 2>/dev/null | \
  openssl x509 -noout -dates
```

## Troubleshooting

### Certificate Validation Issues

#### Certificate Stuck in "Pending Validation"
```bash
# Check if DNS validation records exist
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terragrunt output -raw zone_id) \
  --query 'ResourceRecordSets[?Type==`CNAME` && contains(Name, `_validation`)]'

# Verify DNS propagation
nslookup -type=CNAME _validation-hash.dev.{domain}

# Force recreation of validation records
terragrunt apply -replace="aws_route53_record.validation"
```

#### DNS Propagation Delays
```bash
# Check from multiple DNS servers
dig @8.8.8.8 _validation-hash.dev.{domain} CNAME
dig @1.1.1.1 _validation-hash.dev.{domain} CNAME
dig @ns-123.awsdns-12.com _validation-hash.dev.{domain} CNAME
```

### Common Issues
1. **Domain not delegated**: Ensure nameservers are configured at registrar
2. **Validation timeout**: DNS records must be accessible publicly
3. **Zone mismatch**: Verify hosted zone ID matches domain configuration

## Security Considerations

### Certificate Security
- **Private Keys**: Managed by AWS (never exposed)
- **Certificate Transparency**: All certificates logged publicly
- **Access Control**: Use IAM policies for certificate management

### DNS Security
- **Validation Records**: Keep DNS validation records permanent
- **Zone Access**: Restrict Route53 zone modification permissions
- **Monitoring**: Enable CloudTrail for certificate and DNS changes

## Cost Information

### ACM Certificate Costs
- **Certificate**: No charge for ACM certificates
- **DNS Validation**: Standard Route53 query charges apply
- **Certificate Requests**: No limits or additional charges

### Route53 Costs
- **Validation Queries**: ~$0.40 per million queries
- **Hosted Zone**: $0.50/month (shared across environments)

## Related Documentation

- [ACM Certificate Module](../../../infrastructure-modules/acm-certificate/README.md) - Module documentation
- [Bootstrap README](../../../bootstrap/README.md) - Domain and hosted zone setup
- [Dev Environment README](../README.md) - Development environment overview
- [Staging ACM Certificate](../../staging/acm-certificate/README.md) - Staging environment certificate
- [AWS ACM Documentation](https://docs.aws.amazon.com/acm/) - Official AWS documentation
