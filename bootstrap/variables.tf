variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-terragrunt"
}

variable "domain_name" {
  description = "Primary domain name for the project (e.g., example.com)"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create Route53 hosted zone for the domain"
  type        = bool
  default     = true
}

variable "create_load_balancer_controller_role" {
  description = "Whether to create the AWS Load Balancer Controller IAM role"
  type        = bool
  default     = true
}

variable "create_external_dns_policy" {
  description = "Whether to create the External DNS IAM policy"
  type        = bool
  default     = true
}

variable "create_secrets_manager_policy" {
  description = "Whether to create the Secrets Manager IAM policy"
  type        = bool
  default     = true
}
