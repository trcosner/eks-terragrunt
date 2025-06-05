# Infrastructure Modules

Reusable Terraform modules for EKS platform infrastructure components.

## Module Structure

```
infrastructure-modules/
├── vpc/                    # VPC and networking foundation
├── eks/                    # EKS cluster and node groups  
└── kubernetes-addons/      # Cluster management tools
```

## Module Dependencies

**Layered Architecture**:
1. **VPC**: Foundation networking (no dependencies)
2. **EKS**: Kubernetes cluster (requires VPC outputs)  
3. **Add-ons**: Cluster tools (requires EKS outputs)

## Design Principles

- **Environment Agnostic**: Parameterized for multi-environment use
- **Composable**: Single responsibility, clear interfaces
- **Production Ready**: Security best practices, comprehensive validation
- **AWS Best Practices**: Well-Architected Framework compliance

## Usage

### Terragrunt Integration (Recommended)
```hcl
terraform {
  source = "../../../infrastructure-modules/vpc"
}

inputs = {
  env = local.env
  azs = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets = ["10.0.64.0/19", "10.0.96.0/19"]
}
```
# Test individual modules
cd infrastructure-modules/vpc
terraform init
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
terraform destroy -var-file=test.tfvars
```

### 2. **Integration Testing**
```bash
# Test complete stack
cd infrastructure/dev
terragrunt run-all plan
terragrunt run-all apply --terragrunt-non-interactive
```

### 3. **Validation Testing**
- Infrastructure validation using tools like Terratest
- Security scanning with tools like Checkov or tfsec
- Performance testing of deployed infrastructure

## Customization Guidelines

### Adding New Modules
1. **Create Module Directory**: Follow existing naming conventions
2. **Implement Standard Files**: main.tf, variables.tf, outputs.tf, versions.tf
3. **Documentation**: Create comprehensive README.md
4. **Testing**: Add test configurations and validation
5. **Integration**: Update parent configurations to use new module

### Modifying Existing Modules
1. **Backward Compatibility**: Ensure changes don't break existing deployments
2. **Variable Validation**: Add validation for new input variables
3. **Documentation Updates**: Update README and inline comments
4. **Testing**: Validate changes in development environment
5. **Version Increment**: Follow semantic versioning for releases

## Common Module Patterns

### Variable Definitions
```hcl
variable "env" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Resource Naming
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
    Module      = "vpc"
  }
}
```

### Output Definitions
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

## Troubleshooting

### Module Issues
```bash
# Debug module initialization
terraform init -upgrade

# Validate module configuration
terraform validate

# Check module dependencies
terraform graph | dot -Tpng > graph.png
```

### Common Problems
1. **Version Conflicts**: Update provider version constraints
2. **State Issues**: Use terraform state commands to resolve conflicts
3. **Resource Conflicts**: Check for naming collisions across environments
4. **Permission Issues**: Verify AWS IAM permissions for Terraform operations

## Best Practices

### 1. **Documentation**
- Keep README files up to date
- Document all variables with descriptions and examples
- Include troubleshooting sections for common issues

### 2. **Code Quality**
- Use consistent formatting (terraform fmt)
- Implement comprehensive variable validation
- Follow Terraform naming conventions

### 3. **Security**
- Regular security scanning of module code
- Keep provider versions updated for security patches  
- Implement proper secret management practices

### 4. **Testing**
- Test modules in isolation before integration
- Maintain test configurations for each module
- Automate testing in CI/CD pipelines

## Related Documentation

- [Infrastructure README](../infrastructure/README.md) - Terragrunt configuration patterns
- [Dev Environment](../infrastructure/dev/README.md) - Development environment setup
- [VPC Module](./vpc/README.md) - VPC module documentation
- [EKS Module](./eks/README.md) - EKS module documentation  
- [Kubernetes Add-ons Module](./kubernetes-addons/README.md) - Add-ons module documentation
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html) - Official Terraform recommendations
