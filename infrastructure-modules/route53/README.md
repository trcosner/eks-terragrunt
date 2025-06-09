# Route53 Terraform Module

Creates and manages DNS hosted zones for domain management and SSL certificate validation.

## Features

- **DNS Hosted Zone**: Authoritative DNS management for your domain
- **Nameserver Management**: AWS nameservers for domain delegation
- **Multi-Environment Support**: Environment-specific subdomain management
- **SSL Integration**: DNS validation support for ACM certificates
- **Tag Management**: Consistent resource tagging
- **Cost Optimization**: Efficient DNS query handling

## Module Structure

- `0-versions.tf`: Provider version requirements
- `1-hosted-zone.tf`: Route53 hosted zone resource
- `2-variables.tf`: Input variable definitions
- `3-outputs.tf`: Hosted zone ID and nameserver outputs

## Dependencies

- **Domain Ownership**: Must own the domain to create hosted zone
- **Registrar Access**: Access to update nameservers at domain registrar

## Usage

### Basic Hosted Zone
```hcl
module "route53" {
  source = "./infrastructure-modules/route53"
  
  domain_name = "example.com"
  
  tags = {
    Environment = "shared"
    Module      = "route53"
  }
}
```

### With Environment-Specific Tags
```hcl
module "route53" {
  source = "./infrastructure-modules/route53"
  
  domain_name = "mycompany.com"
  
  tags = {
    Environment = "production"
    Project     = "eks-infrastructure"
    Owner       = "devops-team"
    CostCenter  = "engineering"
  }
}
```

### With Terragrunt (Bootstrap Usage)
```hcl
terraform {
  source = "../infrastructure-modules/route53"
}

inputs = {
  domain_name = "example.com"
  
  tags = {
    Environment = "shared"
    Module      = "route53"
    Project     = "eks-terragrunt"
  }
}
```

## Input Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | `string` | - | **Required**. Domain name for the hosted zone |
| `tags` | `map(string)` | `{}` | Tags to apply to the hosted zone |

## Outputs

| Output | Description |
|--------|-------------|
| `hosted_zone_id` | Route53 hosted zone ID |
| `hosted_zone_arn` | ARN of the hosted zone |
| `name_servers` | List of authoritative nameservers |
| `zone_id` | Alias for hosted_zone_id (for compatibility) |

## Domain Configuration

### Nameserver Delegation
After creating the hosted zone, you must update your domain registrar:

1. **Get AWS Nameservers**:
```bash
terraform output name_servers
# or
aws route53 get-hosted-zone --id /hostedzone/Z123456789ABCDEFGHIJ
```

2. **Update Domain Registrar**:
   - Log into your registrar (Namecheap, GoDaddy, Cloudflare, etc.)
   - Navigate to DNS settings for your domain
   - Change from "Registrar DNS" to "Custom DNS"
   - Enter all 4 AWS nameservers

3. **Verify Propagation**:
```bash
# Check nameserver delegation
dig NS example.com

# Test from multiple locations
nslookup -type=NS example.com 8.8.8.8
nslookup -type=NS example.com 1.1.1.1
```

### DNS Propagation Time
- **Immediate**: Within AWS Route53 network
- **Global**: 15 minutes to 48 hours for full propagation
- **TTL Impact**: Depends on previous DNS record TTL values

## DNS Management

### Adding DNS Records
After hosted zone creation, add DNS records through Terraform or AWS CLI:

```hcl
# A record for apex domain
resource "aws_route53_record" "apex" {
  zone_id = module.route53.hosted_zone_id
  name    = "example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}

# CNAME for www subdomain
resource "aws_route53_record" "www" {
  zone_id = module.route53.hosted_zone_id
  name    = "www.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["example.com"]
}

# MX record for email
resource "aws_route53_record" "mail" {
  zone_id = module.route53.hosted_zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300
  records = ["10 mail.example.com"]
}
```

### Environment Subdomains
```hcl
# Development environment
resource "aws_route53_record" "dev" {
  zone_id = module.route53.hosted_zone_id
  name    = "dev.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.dev_alb.dns_name
    zone_id                = aws_lb.dev_alb.zone_id
    evaluate_target_health = true
  }
}

# Staging environment
resource "aws_route53_record" "staging" {
  zone_id = module.route53.hosted_zone_id
  name    = "staging.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.staging_alb.dns_name
    zone_id                = aws_lb.staging_alb.zone_id
    evaluate_target_health = true
  }
}
```

## SSL Certificate Integration

### ACM Certificate Validation
Route53 hosted zone enables automatic SSL certificate validation:

```hcl
# Certificate with DNS validation
resource "aws_acm_certificate" "this" {
  domain_name       = "*.example.com"
  validation_method = "DNS"
  
  subject_alternative_names = [
    "example.com"
  ]
}

# Validation records (automatic)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.route53.hosted_zone_id
}
```

## Monitoring and Operations

### DNS Query Monitoring
```bash
# Check query statistics
aws route53 get-query-logging-config --id $CONFIG_ID

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 \
  --metric-name QueryCount \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Health Check Integration
```hcl
# Health check for monitoring
resource "aws_route53_health_check" "main" {
  fqdn                            = "example.com"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_logs_region          = "us-east-1"
  cloudwatch_alarm_name           = "route53-health-check"
  insufficient_data_health_status = "Failure"

  tags = {
    Name = "example.com health check"
  }
}

# DNS record with health check
resource "aws_route53_record" "primary" {
  zone_id = module.route53.hosted_zone_id
  name    = "api.example.com"
  type    = "A"
  ttl     = 60

  set_identifier = "primary"
  health_check_id = aws_route53_health_check.main.id

  weighted_routing_policy {
    weight = 100
  }

  records = ["192.0.2.1"]
}
```

### DNS Security
```hcl
# DNSSEC signing (optional)
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = module.route53.hosted_zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "main_ksk"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on = [aws_route53_key_signing_key.main]
  hosted_zone_id = module.route53.hosted_zone_id
}
```

## Cost Management

### Route53 Pricing
- **Hosted Zone**: $0.50 per month per hosted zone
- **DNS Queries**: $0.40 per million queries for first 1 billion queries
- **Health Checks**: $0.50 per health check per month
- **Traffic Policies**: $50.00 per month per policy record

### Cost Optimization Strategies
```bash
# Monitor DNS query patterns
aws route53 list-query-logging-configs

# Optimize TTL values for caching
# Higher TTL = fewer queries = lower cost
```

### Query Logging (Optional)
```hcl
# Enable query logging for cost analysis
resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_group.route53]

  destination_arn = aws_cloudwatch_log_group.route53.arn
  hosted_zone_id  = module.route53.hosted_zone_id
}

resource "aws_cloudwatch_log_group" "route53" {
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = 30
}
```

## Security Features

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/Z123456789ABCDEFGHIJ"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetChange"
      ],
      "Resource": "arn:aws:route53:::change/*"
    }
  ]
}
```

### DNS Filtering and Protection
- **AWS Shield Standard**: DDoS protection (included)
- **AWS Shield Advanced**: Enhanced DDoS protection (optional)
- **Route53 Resolver DNS Firewall**: Domain filtering (optional)

## Troubleshooting

### Common Issues

#### Domain Delegation Not Working
**Symptoms**: DNS queries not resolving to AWS nameservers
**Solutions**:
```bash
# Verify nameservers at registrar
whois example.com | grep -i "name server"

# Check delegation chain
dig +trace example.com

# Verify NS records
dig NS example.com @8.8.8.8
```

#### DNS Propagation Delays
**Symptoms**: DNS changes not visible globally
**Solutions**:
- Wait for TTL expiration of previous records
- Check propagation from multiple locations
- Verify record changes in Route53 console

#### SSL Certificate Validation Failing
**Symptoms**: ACM certificate stuck in "Pending Validation"
**Solutions**:
```bash
# Check validation records exist
aws route53 list-resource-record-sets --hosted-zone-id Z123456789ABCDEFGHIJ \
  --query 'ResourceRecordSets[?Type==`CNAME`]'

# Verify CNAME propagation
dig _validation-hash.example.com CNAME
```

### Diagnostic Commands
```bash
# Check hosted zone details
aws route53 get-hosted-zone --id /hostedzone/Z123456789ABCDEFGHIJ

# List all DNS records
aws route53 list-resource-record-sets --hosted-zone-id Z123456789ABCDEFGHIJ

# Test DNS resolution
nslookup example.com
dig example.com
host example.com

# Check from specific nameserver
dig @ns-123.awsdns-12.com example.com
```

## Multi-Environment Architecture

### Shared Hosted Zone Strategy
```
example.com (shared hosted zone)
├── dev.example.com (development environment)
├── staging.example.com (staging environment)
├── prod.example.com (production environment)
└── www.example.com (production www)
```

### Environment-Specific Records
```hcl
locals {
  environment_records = {
    dev = {
      subdomain = "dev"
      alb_dns   = var.dev_alb_dns_name
      alb_zone  = var.dev_alb_zone_id
    }
    staging = {
      subdomain = "staging"
      alb_dns   = var.staging_alb_dns_name
      alb_zone  = var.staging_alb_zone_id
    }
  }
}

resource "aws_route53_record" "environment" {
  for_each = local.environment_records
  
  zone_id = module.route53.hosted_zone_id
  name    = "${each.value.subdomain}.example.com"
  type    = "A"
  
  alias {
    name                   = each.value.alb_dns
    zone_id                = each.value.alb_zone
    evaluate_target_health = true
  }
}
```

## Best Practices

### 1. **Domain Management**
- Use **single hosted zone** per domain for cost efficiency
- Implement **environment subdomains** for isolation
- Plan **DNS naming conventions** early

### 2. **Record Management**
- Use **alias records** for AWS resources (free queries)
- Set appropriate **TTL values** for caching optimization
- Implement **health checks** for critical services

### 3. **Security**
- Enable **CloudTrail logging** for DNS changes
- Use **IAM policies** for least privilege access
- Consider **DNSSEC** for enhanced security

### 4. **Cost Optimization**
- Use **alias records** instead of CNAME where possible
- Optimize **TTL values** to reduce query volume
- Monitor **query patterns** for optimization opportunities

## Version Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **Domain Registration**: Must be completed before hosted zone creation

## Related Documentation

- [Infrastructure Modules README](../README.md) - Module architecture overview
- [ACM Certificate Module](../acm-certificate/README.md) - SSL certificate management
- [Bootstrap README](../../bootstrap/README.md) - Initial setup and domain configuration
- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/) - Official AWS documentation
- [DNS Best Practices](https://docs.aws.amazon.com/route53/latest/developerguide/best-practices-dns.html) - AWS DNS recommendations
