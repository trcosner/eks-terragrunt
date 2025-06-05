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