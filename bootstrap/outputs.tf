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
  sensitive   = false
}
