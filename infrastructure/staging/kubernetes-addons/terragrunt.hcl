terraform {
  source = "../../../infrastructure-modules/kubernetes-addons"
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-1234567890abcdef0"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "demo"
    openid_connect_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

dependency "acm_certificate" {
  config_path = "../acm-certificate"

  mock_outputs = {
    certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

dependency "bootstrap" {
  config_path = "../../../bootstrap"

  mock_outputs = {
    aws_load_balancer_controller_policy_arn = "arn:aws:iam::123456789012:policy/eks-terragrunt-aws-load-balancer-controller-policy"
    external_dns_policy_arn = "arn:aws:iam::123456789012:policy/eks-terragrunt-external-dns-policy"
    secrets_manager_policy_arn = "arn:aws:iam::123456789012:policy/eks-terragrunt-secrets-manager-policy"
    domain_name = "example.com"
    hosted_zone_id = "Z1234567890ABC"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file(find_in_parent_folders("_envcommon/helm_provider.tf"))
}

generate "kubernetes_provider" {
  path      = "kubernetes-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file(find_in_parent_folders("_envcommon/kubernetes_provider.tf"))
}

inputs = {
  env = include.env.locals.env
  eks_name = dependency.eks.outputs.eks_name
  openid_provider_arn = dependency.eks.outputs.openid_connect_provider_arn
  vpc_id = dependency.vpc.outputs.vpc_id
  enable_cluster_autoscaler = true
  helm_chart_version = "9.28.0"
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_version = "1.8.2"
  ssl_certificate_arn = dependency.acm_certificate.outputs.certificate_arn
  aws_load_balancer_controller_policy_arn = dependency.bootstrap.outputs.aws_load_balancer_controller_policy_arn
  
  # External DNS Configuration
  enable_external_dns = true
  external_dns_version = "1.14.3"
  external_dns_policy_arn = dependency.bootstrap.outputs.external_dns_policy_arn
  domain_name = dependency.bootstrap.outputs.domain_name
  hosted_zone_id = dependency.bootstrap.outputs.hosted_zone_id
  
  # Security Features Configuration
  enable_pod_security_standards = true
  enable_network_policies = true
  enable_secrets_management = true
  secrets_store_csi_driver_version = "1.4.4"
  aws_secrets_provider_version = "0.3.7"
  secrets_manager_policy_arn = dependency.bootstrap.outputs.secrets_manager_policy_arn
  
  # Monitoring Configuration
  enable_monitoring = include.env.locals.enable_monitoring
  prometheus_stack_version = "61.3.2"
  prometheus_retention = "30d"  # Longer retention for staging
  prometheus_storage_size = "50Gi"  # Larger storage for staging
  
  # Grafana Configuration with AWS Secrets Manager
  grafana_use_secrets_manager = true
  grafana_secret_name = "${dependency.eks.outputs.eks_name}-grafana-admin-password-${include.env.locals.env}"
  grafana_service_type = "ClusterIP"  # Use ingress for external access
  enable_grafana_ingress = true
  grafana_hostname = "grafana-staging.${dependency.bootstrap.outputs.domain_name}"
  enable_cloudwatch_exporter = true
  aws_region = include.env.locals.region
  tags = include.env.locals.tags
  
  # EBS CSI Driver Configuration
  enable_ebs_csi_driver = true
  
  # Resource Quotas Configuration
  enable_resource_quotas = true
  default_namespace_cpu_requests = "2"
  default_namespace_cpu_limits = "4"
  default_namespace_memory_requests = "4Gi"
  default_namespace_memory_limits = "8Gi"
  default_namespace_pods = "20"
  kube_system_namespace_cpu_requests = "4"
  kube_system_namespace_cpu_limits = "8"
  kube_system_namespace_memory_requests = "8Gi"
  kube_system_namespace_memory_limits = "16Gi"
  kube_system_namespace_pods = "40"
}