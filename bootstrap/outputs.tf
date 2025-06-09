output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "terraform_role_arn" {
  description = "ARN of the Terraform IAM role"
  value       = aws_iam_role.terraform.arn
}

output "aws_region" {
  description = "AWS region used"
  value       = var.aws_region
}

output "bucket_suffix" {
  description = "Random suffix used for bucket name"
  value       = random_string.bucket_suffix.result
}

# Route53 Outputs
output "domain_name" {
  description = "The primary domain name"
  value       = var.domain_name
}

output "hosted_zone_id" {
  description = "The hosted zone ID for the domain"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : null
}

output "hosted_zone_name_servers" {
  description = "List of name servers for the hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

output "hosted_zone_arn" {
  description = "ARN of the hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].arn : null
}

# AWS Load Balancer Controller IAM Outputs
output "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM policy"
  value       = var.create_load_balancer_controller_role ? aws_iam_policy.aws_load_balancer_controller[0].arn : null
}

# External DNS IAM Outputs
output "external_dns_policy_arn" {
  description = "ARN of the External DNS IAM policy"
  value       = var.create_hosted_zone && var.create_external_dns_policy ? aws_iam_policy.external_dns[0].arn : null
}

# Secrets Manager IAM Outputs
output "secrets_manager_policy_arn" {
  description = "ARN of the Secrets Manager IAM policy"
  value       = var.create_secrets_manager_policy ? aws_iam_policy.secrets_manager[0].arn : null
}
