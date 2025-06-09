# Kubernetes Add-ons Outputs

output "cluster_autoscaler_status" {
  description = "Status of the Cluster Autoscaler deployment"
  value       = var.enable_cluster_autoscaler ? "enabled" : "disabled"
}

output "cluster_autoscaler_version" {
  description = "Version of the Cluster Autoscaler Helm chart deployed"
  value       = var.enable_cluster_autoscaler ? var.helm_chart_version : null
}

output "aws_load_balancer_controller_status" {
  description = "Status of the AWS Load Balancer Controller deployment"
  value       = var.enable_aws_load_balancer_controller ? "enabled" : "disabled"
}

output "aws_load_balancer_controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart deployed"
  value       = var.enable_aws_load_balancer_controller ? var.aws_load_balancer_controller_version : null
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL/TLS certificate for HTTPS ingress"
  value       = var.ssl_certificate_arn
}

output "external_dns_status" {
  description = "Status of the External DNS deployment"
  value       = var.enable_external_dns ? "enabled" : "disabled"
}

output "external_dns_version" {
  description = "Version of the External DNS Helm chart deployed"
  value       = var.enable_external_dns ? var.external_dns_version : null
}

output "external_dns_domain" {
  description = "Domain managed by External DNS"
  value       = var.enable_external_dns ? var.domain_name : null
}

# Security Features Outputs
output "pod_security_standards_enabled" {
  description = "Whether Pod Security Standards are enabled"
  value       = var.enable_pod_security_standards
}

output "network_policies_enabled" {
  description = "Whether Network Policies are enabled"
  value       = var.enable_network_policies
}

output "secrets_management_enabled" {
  description = "Whether AWS Secrets Manager integration is enabled"
  value       = var.enable_secrets_management
}

output "production_namespace" {
  description = "Production namespace with restricted security policies"
  value       = var.enable_pod_security_standards ? "production" : null
}

output "secrets_manager_role_arn" {
  description = "ARN of the IAM role for Secrets Manager access"
  value       = var.enable_secrets_management ? aws_iam_role.secrets_manager_role[0].arn : null
}

output "security_namespaces" {
  description = "List of security-configured namespaces"
  value = var.enable_pod_security_standards ? {
    production  = "restricted"
    staging     = "baseline"
    development = "privileged"
    monitoring  = "baseline"
  } : {}
}

# Monitoring Outputs
output "monitoring_enabled" {
  description = "Whether monitoring stack is enabled"
  value       = var.enable_monitoring
}

output "monitoring_status" {
  description = "Status of the monitoring stack deployment"
  value       = var.enable_monitoring ? "enabled" : "disabled"
}

output "prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart deployed"
  value       = var.enable_monitoring ? var.prometheus_stack_version : null
}

output "grafana_service_name" {
  description = "Name of the Grafana Kubernetes service"
  value       = var.enable_monitoring ? "kube-prometheus-stack-grafana" : null
}

output "grafana_hostname" {
  description = "Hostname for Grafana access (if ingress enabled)"
  value       = var.enable_monitoring && var.enable_grafana_ingress ? var.grafana_hostname : null
}

output "grafana_secret_name" {
  description = "AWS Secrets Manager secret name for Grafana admin password"
  value       = var.enable_monitoring && var.grafana_use_secrets_manager ? aws_secretsmanager_secret.grafana_admin_password[0].name : null
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.enable_monitoring ? "admin" : null
}

output "grafana_namespace" {
  description = "Namespace where Grafana is deployed"
  value       = var.enable_monitoring ? "monitoring" : null
}

output "prometheus_service_name" {
  description = "Name of the Prometheus Kubernetes service"
  value       = var.enable_monitoring ? "kube-prometheus-stack-prometheus" : null
}

output "alertmanager_service_name" {
  description = "Name of the AlertManager Kubernetes service"
  value       = var.enable_monitoring ? "kube-prometheus-stack-alertmanager" : null
}
