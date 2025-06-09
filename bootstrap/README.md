# Bootstrap Configuration

Initial Terraform configuration for setting up foundational AWS resources and state management.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.99.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_state_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.secrets_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.terraform_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_zone.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_string.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_create_external_dns_policy"></a> [create\_external\_dns\_policy](#input\_create\_external\_dns\_policy) | Whether to create the External DNS IAM policy | `bool` | `true` | no |
| <a name="input_create_hosted_zone"></a> [create\_hosted\_zone](#input\_create\_hosted\_zone) | Whether to create Route53 hosted zone for the domain | `bool` | `true` | no |
| <a name="input_create_load_balancer_controller_role"></a> [create\_load\_balancer\_controller\_role](#input\_create\_load\_balancer\_controller\_role) | Whether to create the AWS Load Balancer Controller IAM role | `bool` | `true` | no |
| <a name="input_create_secrets_manager_policy"></a> [create\_secrets\_manager\_policy](#input\_create\_secrets\_manager\_policy) | Whether to create the Secrets Manager IAM policy | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Primary domain name for the project (e.g., example.com) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `"eks-terragrunt"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_load_balancer_controller_policy_arn"></a> [aws\_load\_balancer\_controller\_policy\_arn](#output\_aws\_load\_balancer\_controller\_policy\_arn) | ARN of the AWS Load Balancer Controller IAM policy |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region used |
| <a name="output_bucket_suffix"></a> [bucket\_suffix](#output\_bucket\_suffix) | Random suffix used for bucket name |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The primary domain name |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | ARN of the DynamoDB table for state locking |
| <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name) | Name of the DynamoDB table for state locking |
| <a name="output_external_dns_policy_arn"></a> [external\_dns\_policy\_arn](#output\_external\_dns\_policy\_arn) | ARN of the External DNS IAM policy |
| <a name="output_hosted_zone_arn"></a> [hosted\_zone\_arn](#output\_hosted\_zone\_arn) | ARN of the hosted zone |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The hosted zone ID for the domain |
| <a name="output_hosted_zone_name_servers"></a> [hosted\_zone\_name\_servers](#output\_hosted\_zone\_name\_servers) | List of name servers for the hosted zone |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of the S3 bucket for Terraform state |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket for Terraform state |
| <a name="output_secrets_manager_policy_arn"></a> [secrets\_manager\_policy\_arn](#output\_secrets\_manager\_policy\_arn) | ARN of the Secrets Manager IAM policy |
| <a name="output_terraform_role_arn"></a> [terraform\_role\_arn](#output\_terraform\_role\_arn) | ARN of the Terraform IAM role |
<!-- END_TF_DOCS -->
