variable "env" {
  description = "Environment name"
  type        = string
}

variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Enable or disable the EKS Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "helm_chart_version" {
  description = "Version of the Helm chart to use for the Cluster Autoscaler"
  type        = string
}

variable "openid_provider_arn" {
  description = "ARN of the OpenID Connect provider for EKS"
  type        = string
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable or disable the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.8.2"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL/TLS certificate from ACM for HTTPS ingress"
  type        = string
  default     = ""
}

variable "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM policy from bootstrap"
  type        = string
}

# External DNS Configuration
variable "enable_external_dns" {
  description = "Enable or disable External DNS"
  type        = bool
  default     = true
}

variable "external_dns_version" {
  description = "Version of the External DNS Helm chart"
  type        = string
  default     = "1.14.3"
}

variable "external_dns_policy_arn" {
  description = "ARN of the External DNS IAM policy from bootstrap"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for DNS management"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS management"
  type        = string
}

# Security Features Configuration
variable "enable_pod_security_standards" {
  description = "Enable Pod Security Standards with namespace-based policies"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Network Policies for network segmentation"
  type        = bool
  default     = true
}

variable "enable_secrets_management" {
  description = "Enable AWS Secrets Manager integration with CSI driver"
  type        = bool
  default     = true
}

variable "secrets_store_csi_driver_version" {
  description = "Version of the Secrets Store CSI Driver Helm chart"
  type        = string
  default     = "1.4.4"
}

variable "aws_secrets_provider_version" {
  description = "Version of the AWS Secrets Store CSI Driver Provider"
  type        = string
  default     = "0.3.7"
}

variable "secrets_manager_policy_arn" {
  description = "ARN of the Secrets Manager IAM policy from bootstrap"
  type        = string
}

variable "create_example_secret_provider_class" {
  description = "Whether to create the example SecretProviderClass (only after CSI driver is installed)"
  type        = bool
  default     = false
}