# ACM Certificate Terraform Module

Creates and manages SSL/TLS certificates using AWS Certificate Manager with automatic DNS validation through Route53.

## Features

- **SSL/TLS Certificates**: Wildcard and multi-domain certificate support
- **DNS Validation**: Automatic validation through Route53 DNS records
- **Auto-Renewal**: AWS handles certificate renewal automatically
- **Multi-Environment Support**: Environment-specific certificate management
- **Validation Records**: Automatic creation of DNS validation records
- **Lifecycle Management**: Safe certificate replacement with create_before_destroy

## Module Structure

- `0-versions.tf`: Provider version requirements
- `1-certificate.tf`: ACM certificate and validation records
- `2-variables.tf`: Input variable definitions
- `3-outputs.tf`: Certificate ARN and validation outputs

## Dependencies

- **Route53 Hosted Zone**: Required for DNS validation
- **Domain Ownership**: Must own the domain for certificate issuance

## Usage

### Basic Certificate
```hcl
module "certificate" {
  source = "./infrastructure-modules/acm-certificate"
  
  domain_name      = "example.com"
  validation_method = "DNS"
  zone_id          = "Z123456789ABCDEFGHIJ"
  
  tags = {
    Environment = "dev"
    Module      = "acm-certificate"
  }
}
```

### Wildcard Certificate
```hcl
module "wildcard_certificate" {
  source = "./infrastructure-modules/acm-certificate"
  
  domain_name               = "*.example.com"
  subject_alternative_names = ["example.com"]
  validation_method         = "DNS"
  zone_id                  = "Z123456789ABCDEFGHIJ"
  
  tags = {
    Environment = "production"
    Certificate = "wildcard"
  }
}
```

### Multi-Domain Certificate
```hcl
module "multi_domain_certificate" {
  source = "./infrastructure-modules/acm-certificate"
  
  domain_name = "api.example.com"
  subject_alternative_names = [
    "www.example.com",
    "app.example.com",
    "admin.example.com"
  ]
  validation_method = "DNS"
  zone_id          = "Z123456789ABCDEFGHIJ"
}
```

### With Terragrunt
```hcl
terraform {
  source = "../../../infrastructure-modules/acm-certificate"
}

dependency "route53" {
  config_path = "../route53"
  mock_outputs = {
    hosted_zone_id = "Z123456789ABCDEFGHIJ"
  }
}

inputs = {
  domain_name       = "*.${local.domain_name}"
  subject_alternative_names = [local.domain_name]
  validation_method = "DNS"
  zone_id          = dependency.route53.outputs.hosted_zone_id
  
  tags = {
    Environment = local.env
    Module      = "acm-certificate"
  }
}
```

## Input Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | `string` | - | **Required**. Primary domain name for certificate |
| `subject_alternative_names` | `list(string)` | `[]` | Additional domain names (SANs) |
| `validation_method` | `string` | `"DNS"` | Validation method: `DNS` or `EMAIL` |
| `zone_id` | `string` | `""` | Route53 hosted zone ID for DNS validation |
| `create_route53_records` | `bool` | `true` | Whether to create DNS validation records |
| `tags` | `map(string)` | `{}` | Tags for certificate resources |

## Outputs

| Output | Description |
|--------|-------------|
| `certificate_arn` | ARN of the issued certificate |
| `certificate_domain_name` | Domain name of the certificate |
| `certificate_status` | Validation status of the certificate |
| `domain_validation_options` | Domain validation details |

## Certificate Validation

### DNS Validation Process
1. **Request Certificate**: ACM creates certificate request
2. **Create DNS Records**: Module creates validation records in Route53
3. **Automatic Validation**: AWS validates domain ownership
4. **Certificate Issuance**: Certificate becomes `ISSUED` status

### Validation Time
- **Initial Issuance**: 5-30 minutes after DNS propagation
- **Renewal**: Automatic, no downtime
- **DNS Propagation**: Usually 5-15 minutes

### Validation Verification
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn arn:aws:acm:region:account:certificate/cert-id

# Verify DNS records
dig _validation.example.com CNAME

# Check certificate in browser
openssl s_client -connect example.com:443 -servername example.com
```

## Certificate Management

### Certificate Renewal
ACM certificates auto-renew 60 days before expiration:
- **No manual intervention** required
- **DNS validation records** must remain in place
- **Load balancers/services** automatically use new certificate

### Certificate Replacement
```hcl
# The lifecycle rule ensures safe replacement
lifecycle {
  create_before_destroy = true
}
```

### Certificate Monitoring
```bash
# Monitor certificate expiration
aws acm list-certificates --certificate-statuses ISSUED \
  --query 'CertificateSummaryList[*].[DomainName,NotAfter]' \
  --output table

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CertificateManager \
  --metric-name DaysToExpiry \
  --dimensions Name=CertificateArn,Value=arn:aws:acm:region:account:certificate/cert-id
```

## Environment Integration

### Development Environment
```hcl
# dev.example.com certificate
domain_name = "*.dev.example.com"
subject_alternative_names = ["dev.example.com"]
```

### Staging Environment
```hcl
# staging.example.com certificate
domain_name = "*.staging.example.com"
subject_alternative_names = ["staging.example.com"]
```

### Production Environment
```hcl
# production certificate with apex domain
domain_name = "*.example.com"
subject_alternative_names = ["example.com"]
```

## Security Features

### Encryption Standards
- **RSA-2048** or **ECDSA P-256** key algorithms
- **SHA-256** signature algorithm
- **TLS 1.2/1.3** protocol support

### Certificate Transparency
- All certificates logged in **Certificate Transparency logs**
- Public visibility of certificate issuance
- Protection against unauthorized certificates

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:RequestCertificate",
        "acm:AddTagsToCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetChange"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/Z123456789ABCDEFGHIJ",
        "arn:aws:route53:::change/*"
      ]
    }
  ]
}
```

## Troubleshooting

### Common Issues

#### Certificate Stuck in "Pending Validation"
**Symptoms**: Certificate status remains `PENDING_VALIDATION`
**Causes**:
- DNS validation records not created/propagated
- Incorrect Route53 hosted zone
- Domain not owned by AWS account

**Solutions**:
```bash
# Check validation records exist
aws route53 list-resource-record-sets --hosted-zone-id Z123456789ABCDEFGHIJ \
  --query 'ResourceRecordSets[?Type==`CNAME`]'

# Verify DNS propagation
dig _validation-hash.example.com CNAME

# Re-create validation records
terragrunt apply -replace="aws_route53_record.validation"
```

#### DNS Validation Records Not Created
**Symptoms**: No CNAME validation records in Route53
**Solutions**:
- Verify `zone_id` parameter is correct
- Ensure `create_route53_records = true`
- Check Route53 permissions for record creation

#### Certificate Not Renewed
**Symptoms**: Certificate expired despite auto-renewal
**Causes**:
- DNS validation records deleted
- Route53 hosted zone changes
- Domain ownership issues

**Solutions**:
- Ensure validation records remain in Route53
- Verify domain ownership hasn't changed
- Check ACM service quotas

### Validation Commands
```bash
# Check certificate details
aws acm describe-certificate --certificate-arn $CERT_ARN

# List all certificates
aws acm list-certificates --certificate-statuses ISSUED,PENDING_VALIDATION

# Check DNS propagation
nslookup -type=CNAME _validation.example.com 8.8.8.8

# Test certificate chain
openssl s_client -connect example.com:443 -servername example.com -showcerts
```

## Cost Optimization

### Certificate Costs
- **ACM Certificates**: No additional charge
- **DNS Validation**: Standard Route53 query charges
- **Certificate Requests**: No limits or charges

### Cost Monitoring
```bash
# Route53 query costs (validation traffic)
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://route53-filter.json
```

## Best Practices

### 1. **Certificate Design**
- Use **wildcard certificates** for multiple subdomains
- Include **apex domain** in SAN list for wildcard certificates
- Plan certificate domains based on application architecture

### 2. **Validation Management**
- Keep **DNS validation records** permanent
- Use **Infrastructure as Code** for validation records
- Monitor **DNS propagation** during initial setup

### 3. **Security**
- Enable **Certificate Transparency** monitoring
- Implement **certificate monitoring** and alerting
- Use **least privilege** IAM policies

### 4. **Operations**
- Test certificate **auto-renewal** process
- Monitor **certificate expiration** dates
- Implement **certificate inventory** management

## Version Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **Route53**: Hosted zone must exist before certificate creation

## Related Documentation

- [Infrastructure Modules README](../README.md) - Module architecture overview
- [Route53 Module](../route53/README.md) - DNS hosted zone management
- [Dev ACM Certificate](../../infrastructure/dev/acm-certificate/README.md) - Usage example
- [AWS ACM Documentation](https://docs.aws.amazon.com/acm/) - Official AWS documentation
- [Certificate Transparency](https://certificate.transparency.dev/) - CT log information
