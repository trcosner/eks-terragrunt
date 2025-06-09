# EKS Terraform Module

Creates an Amazon EKS cluster with managed node groups, IAM roles, and OIDC provider integration.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.99.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_name"></a> [eks\_name](#input\_eks\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | Version of the EKS cluster | `string` | n/a | yes |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Determines whether to create an Open ID Connect Provider for EKS to enable IRSA | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name, e.g. staging, production | `string` | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of EKS node groups with their configurations | <pre>map(object({<br/>    capacity_type = string<br/>    instance_types = list(string)<br/>    scaling_config = object({<br/>      desired_size = number<br/>      max_size     = number<br/>      min_size     = number<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_node_iam_policies"></a> [node\_iam\_policies](#input\_node\_iam\_policies) | Map of IAM policies to attach to the EKS node group role | `map(any)` | <pre>{<br/>  "1": "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",<br/>  "2": "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",<br/>  "3": "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",<br/>  "4": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"<br/>}</pre> | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_eks_name"></a> [eks\_name](#output\_eks\_name) | The name of the EKS cluster |
| <a name="output_openid_connect_provider_arn"></a> [openid\_connect\_provider\_arn](#output\_openid\_connect\_provider\_arn) | The ARN of the OpenID Connect provider for the EKS cluster |
<!-- END_TF_DOCS -->
