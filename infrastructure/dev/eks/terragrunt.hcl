terraform {
  source = "../../../infrastructure-modules/eks"
}

include "root" {
  path = find_in_parent_folders()
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
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 1
        max_size = 5
        min_size = 1
      }
    }
  }
}



