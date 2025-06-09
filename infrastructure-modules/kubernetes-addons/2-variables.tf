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

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable or disable the monitoring stack (Prometheus + Grafana)"
  type        = bool
  default     = false
}

variable "prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "61.3.2"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "30d"
}

variable "prometheus_retention_size" {
  description = "Prometheus data retention size"
  type        = string
  default     = "45GB"
}

variable "prometheus_storage_enabled" {
  description = "Enable persistent storage for Prometheus"
  type        = bool
  default     = true
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus persistent volume"
  type        = string
  default     = "gp2"
}

variable "prometheus_storage_size" {
  description = "Size of Prometheus persistent volume"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (use AWS Secrets Manager in production)"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "grafana_use_secrets_manager" {
  description = "Use AWS Secrets Manager for Grafana admin password instead of hardcoded value"
  type        = bool
  default     = true
}

variable "grafana_secret_name" {
  description = "AWS Secrets Manager secret name for Grafana admin password"
  type        = string
  default     = ""
}

variable "grafana_persistence_enabled" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "grafana_storage_class" {
  description = "Storage class for Grafana persistent volume"
  type        = string
  default     = "gp2"
}

variable "grafana_storage_size" {
  description = "Size of Grafana persistent volume"
  type        = string
  default     = "10Gi"
}

variable "grafana_service_type" {
  description = "Kubernetes service type for Grafana (ClusterIP, LoadBalancer, NodePort)"
  type        = string
  default     = "ClusterIP"
}

variable "enable_grafana_ingress" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_hostname" {
  description = "Hostname for Grafana ingress (if enabled)"
  type        = string
  default     = ""
}

variable "alertmanager_storage_enabled" {
  description = "Enable persistent storage for AlertManager"
  type        = bool
  default     = true
}

variable "alertmanager_storage_class" {
  description = "Storage class for AlertManager persistent volume"
  type        = string
  default     = "gp2"
}

variable "alertmanager_storage_size" {
  description = "Size of AlertManager persistent volume"
  type        = string
  default     = "10Gi"
}

variable "enable_cloudwatch_exporter" {
  description = "Enable CloudWatch Exporter for AWS metrics"
  type        = bool
  default     = false
}

variable "cloudwatch_exporter_version" {
  description = "Version of the CloudWatch Exporter Helm chart"
  type        = string
  default     = "0.25.3"
}

variable "aws_region" {
  description = "AWS region for CloudWatch metrics"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Resource Quota Variables
variable "enable_resource_quotas" {
  description = "Enable resource quotas for namespaces"
  type        = bool
  default     = true
}

# Default namespace resource quotas
variable "default_namespace_cpu_requests" {
  description = "CPU requests limit for default namespace"
  type        = string
  default     = "2"
}

variable "default_namespace_memory_requests" {
  description = "Memory requests limit for default namespace"
  type        = string
  default     = "4Gi"
}

variable "default_namespace_cpu_limits" {
  description = "CPU limits for default namespace"
  type        = string
  default     = "4"
}

variable "default_namespace_memory_limits" {
  description = "Memory limits for default namespace"
  type        = string
  default     = "8Gi"
}

variable "default_namespace_pod_limit" {
  description = "Pod limit for default namespace"
  type        = string
  default     = "10"
}

# Kube-system namespace resource quotas
variable "kube_system_namespace_cpu_requests" {
  description = "CPU requests limit for kube-system namespace"
  type        = string
  default     = "4"
}

variable "kube_system_namespace_memory_requests" {
  description = "Memory requests limit for kube-system namespace"
  type        = string
  default     = "8Gi"
}

variable "kube_system_namespace_cpu_limits" {
  description = "CPU limits for kube-system namespace"
  type        = string
  default     = "8"
}

variable "kube_system_namespace_memory_limits" {
  description = "Memory limits for kube-system namespace"
  type        = string
  default     = "16Gi"
}

variable "kube_system_namespace_pod_limit" {
  description = "Pod limit for kube-system namespace"
  type        = string
  default     = "20"
}

# Enhanced AWS CloudWatch Integration Variables
variable "enable_aws_service_dashboards" {
  description = "Enable pre-built AWS service dashboards in Grafana"
  type        = bool
  default     = true
}

variable "cloudwatch_metrics_collection_interval" {
  description = "Collection interval for CloudWatch metrics (in seconds)"
  type        = number
  default     = 300
}

variable "enable_ec2_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "enable_alb_monitoring" {
  description = "Enable CloudWatch monitoring for Application Load Balancers"
  type        = bool
  default     = true
}

variable "enable_nat_gateway_monitoring" {
  description = "Enable CloudWatch monitoring for NAT Gateways"
  type        = bool
  default     = true
}

variable "enable_route53_monitoring" {
  description = "Enable CloudWatch monitoring for Route53"
  type        = bool
  default     = false
}

# EBS CSI Driver Configuration
variable "enable_ebs_csi_driver" {
  description = "Enable or disable the EBS CSI driver for persistent storage"
  type        = bool
  default     = true
}