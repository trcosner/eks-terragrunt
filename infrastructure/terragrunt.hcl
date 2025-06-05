locals {
    # Using the bucket suffix from bootstrap outputs
    bucket_suffix = "o1169f0t"
}

remote_state {
    backend = "s3"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }

    config = {
        bucket         = "eks-terragrunt-terraform-state-${local.bucket_suffix}"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "eks-terragrunt-terraform-state-lock"
    }
}

generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents  = file(find_in_parent_folders("_envcommon/aws_provider.tf"))
}