# Bootstrap Terraform Backend

This directory contains the bootstrap infrastructure needed to set up remote state management for the EKS Terragrunt project.

## Infrastructure Created

- **S3 Bucket**: Terraform state storage with versioning and encryption
- **DynamoDB Table**: State locking to prevent concurrent operations
- **IAM Role**: Administrative access for Terraform operations

## Usage

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

After deployment, update `infrastructure/terragrunt.hcl` with the `bucket_suffix` output:

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "eks-terragrunt-terraform-state-{bucket_suffix}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "eks-terragrunt-terraform-state-lock"
  }
}
```

## Cleanup

```bash
terraform destroy
```

**Warning**: Destroy all other infrastructure first.
