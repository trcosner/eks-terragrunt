# Kubernetes Add-ons Outputs

output "cluster_autoscaler_status" {
  description = "Status of the Cluster Autoscaler deployment"
  value       = var.enable_cluster_autoscaler ? "enabled" : "disabled"
}

output "cluster_autoscaler_version" {
  description = "Version of the Cluster Autoscaler Helm chart deployed"
  value       = var.enable_cluster_autoscaler ? var.helm_chart_version : null
}
