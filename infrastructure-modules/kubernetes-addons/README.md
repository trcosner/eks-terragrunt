# Kubernetes Addons Module

Comprehensive Kubernetes add-ons module that deploys and configures essential platform services including:

- **Cluster Management**: Cluster Autoscaler for dynamic node scaling
- **Load Balancing**: AWS Load Balancer Controller for ALB/NLB management
- **DNS Automation**: External DNS for automatic Route53 record management
- **Security**: Pod Security Standards, Network Policies, and RBAC
- **Secrets Management**: AWS Secrets Manager integration with CSI driver
- **Monitoring**: Complete observability stack with Prometheus, Grafana, and AlertManager
- **Storage**: EBS CSI driver for persistent volume support
- **Resource Management**: Namespace quotas and resource limits

This module transforms a basic EKS cluster into a production-ready platform with security, observability, and operational excellence built-in.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.9 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.99.1 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.23 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ebs_csi_driver_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.prometheus_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.secrets_manager_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.prometheus_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller_bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.secrets_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.grafana_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.grafana_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cloudwatch_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kube_prometheus_stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.secrets_store_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.secrets_store_csi_driver_aws](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.gp2_not_default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_config_map.aws_dashboards](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_manifest.example_secret_provider_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.grafana_secret_provider_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.pod_security_policy_template](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.development](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.production](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.staging_apps](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.development_allow_all](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.monitoring_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.production_allow_alb_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.production_allow_internal](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.production_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.production_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.staging_allow_all](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_resource_quota.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |
| [kubernetes_resource_quota.kube_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |
| [kubernetes_secret.grafana_admin_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.secrets_manager_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_storage_class.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [random_password.grafana_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluser_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#input\_alertmanager\_storage\_class) | Storage class for AlertManager persistent volume | `string` | `"gp2"` | no |
| <a name="input_alertmanager_storage_enabled"></a> [alertmanager\_storage\_enabled](#input\_alertmanager\_storage\_enabled) | Enable persistent storage for AlertManager | `bool` | `true` | no |
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | Size of AlertManager persistent volume | `string` | `"10Gi"` | no |
| <a name="input_aws_load_balancer_controller_policy_arn"></a> [aws\_load\_balancer\_controller\_policy\_arn](#input\_aws\_load\_balancer\_controller\_policy\_arn) | ARN of the AWS Load Balancer Controller IAM policy from bootstrap | `string` | n/a | yes |
| <a name="input_aws_load_balancer_controller_version"></a> [aws\_load\_balancer\_controller\_version](#input\_aws\_load\_balancer\_controller\_version) | Version of the AWS Load Balancer Controller Helm chart | `string` | `"1.8.2"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for CloudWatch metrics | `string` | `"us-east-1"` | no |
| <a name="input_aws_secrets_provider_version"></a> [aws\_secrets\_provider\_version](#input\_aws\_secrets\_provider\_version) | Version of the AWS Secrets Store CSI Driver Provider | `string` | `"0.3.7"` | no |
| <a name="input_cloudwatch_exporter_version"></a> [cloudwatch\_exporter\_version](#input\_cloudwatch\_exporter\_version) | Version of the CloudWatch Exporter Helm chart | `string` | `"0.25.3"` | no |
| <a name="input_cloudwatch_metrics_collection_interval"></a> [cloudwatch\_metrics\_collection\_interval](#input\_cloudwatch\_metrics\_collection\_interval) | Collection interval for CloudWatch metrics (in seconds) | `number` | `300` | no |
| <a name="input_create_example_secret_provider_class"></a> [create\_example\_secret\_provider\_class](#input\_create\_example\_secret\_provider\_class) | Whether to create the example SecretProviderClass (only after CSI driver is installed) | `bool` | `false` | no |
| <a name="input_default_namespace_cpu_limits"></a> [default\_namespace\_cpu\_limits](#input\_default\_namespace\_cpu\_limits) | CPU limits for default namespace | `string` | `"4"` | no |
| <a name="input_default_namespace_cpu_requests"></a> [default\_namespace\_cpu\_requests](#input\_default\_namespace\_cpu\_requests) | CPU requests limit for default namespace | `string` | `"2"` | no |
| <a name="input_default_namespace_memory_limits"></a> [default\_namespace\_memory\_limits](#input\_default\_namespace\_memory\_limits) | Memory limits for default namespace | `string` | `"8Gi"` | no |
| <a name="input_default_namespace_memory_requests"></a> [default\_namespace\_memory\_requests](#input\_default\_namespace\_memory\_requests) | Memory requests limit for default namespace | `string` | `"4Gi"` | no |
| <a name="input_default_namespace_pod_limit"></a> [default\_namespace\_pod\_limit](#input\_default\_namespace\_pod\_limit) | Pod limit for default namespace | `string` | `"10"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Primary domain name for DNS management | `string` | n/a | yes |
| <a name="input_eks_name"></a> [eks\_name](#input\_eks\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_enable_alb_monitoring"></a> [enable\_alb\_monitoring](#input\_enable\_alb\_monitoring) | Enable CloudWatch monitoring for Application Load Balancers | `bool` | `true` | no |
| <a name="input_enable_aws_load_balancer_controller"></a> [enable\_aws\_load\_balancer\_controller](#input\_enable\_aws\_load\_balancer\_controller) | Enable or disable the AWS Load Balancer Controller | `bool` | `true` | no |
| <a name="input_enable_aws_service_dashboards"></a> [enable\_aws\_service\_dashboards](#input\_enable\_aws\_service\_dashboards) | Enable pre-built AWS service dashboards in Grafana | `bool` | `true` | no |
| <a name="input_enable_cloudwatch_exporter"></a> [enable\_cloudwatch\_exporter](#input\_enable\_cloudwatch\_exporter) | Enable CloudWatch Exporter for AWS metrics | `bool` | `false` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable or disable the EKS Cluster Autoscaler | `bool` | `true` | no |
| <a name="input_enable_ebs_csi_driver"></a> [enable\_ebs\_csi\_driver](#input\_enable\_ebs\_csi\_driver) | Enable or disable the EBS CSI driver for persistent storage | `bool` | `true` | no |
| <a name="input_enable_ec2_detailed_monitoring"></a> [enable\_ec2\_detailed\_monitoring](#input\_enable\_ec2\_detailed\_monitoring) | Enable detailed CloudWatch monitoring for EC2 instances | `bool` | `true` | no |
| <a name="input_enable_external_dns"></a> [enable\_external\_dns](#input\_enable\_external\_dns) | Enable or disable External DNS | `bool` | `true` | no |
| <a name="input_enable_grafana_ingress"></a> [enable\_grafana\_ingress](#input\_enable\_grafana\_ingress) | Enable ingress for Grafana | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable or disable the monitoring stack (Prometheus + Grafana) | `bool` | `false` | no |
| <a name="input_enable_nat_gateway_monitoring"></a> [enable\_nat\_gateway\_monitoring](#input\_enable\_nat\_gateway\_monitoring) | Enable CloudWatch monitoring for NAT Gateways | `bool` | `true` | no |
| <a name="input_enable_network_policies"></a> [enable\_network\_policies](#input\_enable\_network\_policies) | Enable Network Policies for network segmentation | `bool` | `true` | no |
| <a name="input_enable_pod_security_standards"></a> [enable\_pod\_security\_standards](#input\_enable\_pod\_security\_standards) | Enable Pod Security Standards with namespace-based policies | `bool` | `true` | no |
| <a name="input_enable_resource_quotas"></a> [enable\_resource\_quotas](#input\_enable\_resource\_quotas) | Enable resource quotas for namespaces | `bool` | `true` | no |
| <a name="input_enable_route53_monitoring"></a> [enable\_route53\_monitoring](#input\_enable\_route53\_monitoring) | Enable CloudWatch monitoring for Route53 | `bool` | `false` | no |
| <a name="input_enable_secrets_management"></a> [enable\_secrets\_management](#input\_enable\_secrets\_management) | Enable AWS Secrets Manager integration with CSI driver | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_external_dns_policy_arn"></a> [external\_dns\_policy\_arn](#input\_external\_dns\_policy\_arn) | ARN of the External DNS IAM policy from bootstrap | `string` | n/a | yes |
| <a name="input_external_dns_version"></a> [external\_dns\_version](#input\_external\_dns\_version) | Version of the External DNS Helm chart | `string` | `"1.14.3"` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Admin password for Grafana (use AWS Secrets Manager in production) | `string` | `"admin123"` | no |
| <a name="input_grafana_hostname"></a> [grafana\_hostname](#input\_grafana\_hostname) | Hostname for Grafana ingress (if enabled) | `string` | `""` | no |
| <a name="input_grafana_persistence_enabled"></a> [grafana\_persistence\_enabled](#input\_grafana\_persistence\_enabled) | Enable persistent storage for Grafana | `bool` | `true` | no |
| <a name="input_grafana_secret_name"></a> [grafana\_secret\_name](#input\_grafana\_secret\_name) | AWS Secrets Manager secret name for Grafana admin password | `string` | `""` | no |
| <a name="input_grafana_service_type"></a> [grafana\_service\_type](#input\_grafana\_service\_type) | Kubernetes service type for Grafana (ClusterIP, LoadBalancer, NodePort) | `string` | `"ClusterIP"` | no |
| <a name="input_grafana_storage_class"></a> [grafana\_storage\_class](#input\_grafana\_storage\_class) | Storage class for Grafana persistent volume | `string` | `"gp2"` | no |
| <a name="input_grafana_storage_size"></a> [grafana\_storage\_size](#input\_grafana\_storage\_size) | Size of Grafana persistent volume | `string` | `"10Gi"` | no |
| <a name="input_grafana_use_secrets_manager"></a> [grafana\_use\_secrets\_manager](#input\_grafana\_use\_secrets\_manager) | Use AWS Secrets Manager for Grafana admin password instead of hardcoded value | `bool` | `true` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of the Helm chart to use for the Cluster Autoscaler | `string` | n/a | yes |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | Route53 hosted zone ID for DNS management | `string` | n/a | yes |
| <a name="input_kube_system_namespace_cpu_limits"></a> [kube\_system\_namespace\_cpu\_limits](#input\_kube\_system\_namespace\_cpu\_limits) | CPU limits for kube-system namespace | `string` | `"8"` | no |
| <a name="input_kube_system_namespace_cpu_requests"></a> [kube\_system\_namespace\_cpu\_requests](#input\_kube\_system\_namespace\_cpu\_requests) | CPU requests limit for kube-system namespace | `string` | `"4"` | no |
| <a name="input_kube_system_namespace_memory_limits"></a> [kube\_system\_namespace\_memory\_limits](#input\_kube\_system\_namespace\_memory\_limits) | Memory limits for kube-system namespace | `string` | `"16Gi"` | no |
| <a name="input_kube_system_namespace_memory_requests"></a> [kube\_system\_namespace\_memory\_requests](#input\_kube\_system\_namespace\_memory\_requests) | Memory requests limit for kube-system namespace | `string` | `"8Gi"` | no |
| <a name="input_kube_system_namespace_pod_limit"></a> [kube\_system\_namespace\_pod\_limit](#input\_kube\_system\_namespace\_pod\_limit) | Pod limit for kube-system namespace | `string` | `"20"` | no |
| <a name="input_openid_provider_arn"></a> [openid\_provider\_arn](#input\_openid\_provider\_arn) | ARN of the OpenID Connect provider for EKS | `string` | n/a | yes |
| <a name="input_prometheus_retention"></a> [prometheus\_retention](#input\_prometheus\_retention) | Prometheus data retention period | `string` | `"30d"` | no |
| <a name="input_prometheus_retention_size"></a> [prometheus\_retention\_size](#input\_prometheus\_retention\_size) | Prometheus data retention size | `string` | `"45GB"` | no |
| <a name="input_prometheus_stack_version"></a> [prometheus\_stack\_version](#input\_prometheus\_stack\_version) | Version of the kube-prometheus-stack Helm chart | `string` | `"61.3.2"` | no |
| <a name="input_prometheus_storage_class"></a> [prometheus\_storage\_class](#input\_prometheus\_storage\_class) | Storage class for Prometheus persistent volume | `string` | `"gp2"` | no |
| <a name="input_prometheus_storage_enabled"></a> [prometheus\_storage\_enabled](#input\_prometheus\_storage\_enabled) | Enable persistent storage for Prometheus | `bool` | `true` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Size of Prometheus persistent volume | `string` | `"50Gi"` | no |
| <a name="input_secrets_manager_policy_arn"></a> [secrets\_manager\_policy\_arn](#input\_secrets\_manager\_policy\_arn) | ARN of the Secrets Manager IAM policy from bootstrap | `string` | n/a | yes |
| <a name="input_secrets_store_csi_driver_version"></a> [secrets\_store\_csi\_driver\_version](#input\_secrets\_store\_csi\_driver\_version) | Version of the Secrets Store CSI Driver Helm chart | `string` | `"1.4.4"` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | ARN of the SSL/TLS certificate from ACM for HTTPS ingress | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the EKS cluster is deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alertmanager_service_name"></a> [alertmanager\_service\_name](#output\_alertmanager\_service\_name) | Name of the AlertManager Kubernetes service |
| <a name="output_aws_load_balancer_controller_status"></a> [aws\_load\_balancer\_controller\_status](#output\_aws\_load\_balancer\_controller\_status) | Status of the AWS Load Balancer Controller deployment |
| <a name="output_aws_load_balancer_controller_version"></a> [aws\_load\_balancer\_controller\_version](#output\_aws\_load\_balancer\_controller\_version) | Version of the AWS Load Balancer Controller Helm chart deployed |
| <a name="output_cluster_autoscaler_status"></a> [cluster\_autoscaler\_status](#output\_cluster\_autoscaler\_status) | Status of the Cluster Autoscaler deployment |
| <a name="output_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#output\_cluster\_autoscaler\_version) | Version of the Cluster Autoscaler Helm chart deployed |
| <a name="output_external_dns_domain"></a> [external\_dns\_domain](#output\_external\_dns\_domain) | Domain managed by External DNS |
| <a name="output_external_dns_status"></a> [external\_dns\_status](#output\_external\_dns\_status) | Status of the External DNS deployment |
| <a name="output_external_dns_version"></a> [external\_dns\_version](#output\_external\_dns\_version) | Version of the External DNS Helm chart deployed |
| <a name="output_grafana_admin_user"></a> [grafana\_admin\_user](#output\_grafana\_admin\_user) | Grafana admin username |
| <a name="output_grafana_hostname"></a> [grafana\_hostname](#output\_grafana\_hostname) | Hostname for Grafana access (if ingress enabled) |
| <a name="output_grafana_namespace"></a> [grafana\_namespace](#output\_grafana\_namespace) | Namespace where Grafana is deployed |
| <a name="output_grafana_secret_name"></a> [grafana\_secret\_name](#output\_grafana\_secret\_name) | AWS Secrets Manager secret name for Grafana admin password |
| <a name="output_grafana_service_name"></a> [grafana\_service\_name](#output\_grafana\_service\_name) | Name of the Grafana Kubernetes service |
| <a name="output_monitoring_enabled"></a> [monitoring\_enabled](#output\_monitoring\_enabled) | Whether monitoring stack is enabled |
| <a name="output_monitoring_status"></a> [monitoring\_status](#output\_monitoring\_status) | Status of the monitoring stack deployment |
| <a name="output_network_policies_enabled"></a> [network\_policies\_enabled](#output\_network\_policies\_enabled) | Whether Network Policies are enabled |
| <a name="output_pod_security_standards_enabled"></a> [pod\_security\_standards\_enabled](#output\_pod\_security\_standards\_enabled) | Whether Pod Security Standards are enabled |
| <a name="output_production_namespace"></a> [production\_namespace](#output\_production\_namespace) | Production namespace with restricted security policies |
| <a name="output_prometheus_service_name"></a> [prometheus\_service\_name](#output\_prometheus\_service\_name) | Name of the Prometheus Kubernetes service |
| <a name="output_prometheus_stack_version"></a> [prometheus\_stack\_version](#output\_prometheus\_stack\_version) | Version of the kube-prometheus-stack Helm chart deployed |
| <a name="output_secrets_management_enabled"></a> [secrets\_management\_enabled](#output\_secrets\_management\_enabled) | Whether AWS Secrets Manager integration is enabled |
| <a name="output_secrets_manager_role_arn"></a> [secrets\_manager\_role\_arn](#output\_secrets\_manager\_role\_arn) | ARN of the IAM role for Secrets Manager access |
| <a name="output_security_namespaces"></a> [security\_namespaces](#output\_security\_namespaces) | List of security-configured namespaces |
| <a name="output_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#output\_ssl\_certificate\_arn) | ARN of the SSL/TLS certificate for HTTPS ingress |
<!-- END_TF_DOCS -->
