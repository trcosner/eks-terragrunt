include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

# Get the domain configuration from bootstrap
dependency "bootstrap" {
  config_path = "../../../bootstrap"

  mock_outputs = {
    domain_name       = "example.com"
    hosted_zone_id    = "Z1234567890ABC"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "fmt", "apply", "plan", "init"]
}

terraform {
  source = "../../../infrastructure-modules//acm-certificate"
}

inputs = {
  domain_name                = "dev.${dependency.bootstrap.outputs.domain_name}"
  subject_alternative_names  = ["*.dev.${dependency.bootstrap.outputs.domain_name}"]
  validation_method          = "DNS"
  create_route53_records     = true
  zone_id                   = dependency.bootstrap.outputs.hosted_zone_id
  
  tags = merge(
    include.env.locals.tags,
    {
      Name        = "dev-demo-certificate"
      Environment = "dev"
      Purpose     = "SSL certificate for dev demo applications"
    }
  )
}
