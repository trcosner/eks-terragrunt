# Bootstrap doesn't need root include since it's not part of infrastructure hierarchy

terraform {
  source = "."
}

inputs = {
  aws_region = "us-east-1"
  project_name = "eks-terragrunt"
  create_hosted_zone = true
  create_load_balancer_controller_role = true
  create_external_dns_policy = true
}
