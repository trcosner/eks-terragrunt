terraform {
  source = "../../../infrastructure-modules/eks"
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
    path = find_in_parent_folders("env.hcl")
    expose = true
    merge_strategy = "no_merge"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.env_vars.locals.env
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnets = ["subnet-1234", "subnet-5678"] 
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

inputs = {
  eks_version = "1.33"
  env = local.env
  eks_name = "demo"
  subnet_ids = dependency.vpc.outputs.private_subnets  
  
  node_groups = {
    general = {
      capacity_type = "ON_DEMAND"
      instance_types = include.env.locals.node_instance_types
      scaling_config = {
        desired_size = include.env.locals.min_nodes
        max_size = include.env.locals.max_nodes
        min_size = include.env.locals.min_nodes
      }
    }
  }
  
  tags = include.env.locals.tags
}



