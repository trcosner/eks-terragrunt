terraform {
  source = "../../../infrastructure-modules/kubernetes-addons"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.env_vars.locals.env
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "demo"
    openid_connect_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file(find_in_parent_folders("_envcommon/helm_provider.tf"))
}

inputs = {
  env = local.env
  eks_name = dependency.eks.outputs.eks_name
  openid_provider_arn = dependency.eks.outputs.openid_connect_provider_arn
  enable_cluster_autoscaler = true
  helm_chart_version = "9.28.0"
}
