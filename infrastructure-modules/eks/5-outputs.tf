output "eks_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "openid_connect_provider_arn" {
  description = "The ARN of the OpenID Connect provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.this[0].arn
}