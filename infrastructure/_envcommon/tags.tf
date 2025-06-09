# Common tagging strategy for all resources
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
    Repository  = "eks-terragrunt-demo"
    CostCenter  = var.cost_center
    Owner       = var.owner
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-terragrunt-demo"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "owner" {
  description = "Team or person responsible for the resources"
  type        = string
  default     = "devops-team"
}
