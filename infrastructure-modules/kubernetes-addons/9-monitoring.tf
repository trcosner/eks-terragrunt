# Monitoring Stack with Prometheus and Grafana
# Uses the monitoring namespace created in 6-pod-security.tf

# AWS Secrets Manager secret for Grafana admin password
resource "aws_secretsmanager_secret" "grafana_admin_password" {
  count       = var.enable_monitoring && var.grafana_use_secrets_manager ? 1 : 0
  name        = var.grafana_secret_name != "" ? var.grafana_secret_name : "${var.eks_name}-grafana-admin-password-${var.env}"
  description = "Grafana admin password for ${var.eks_name} ${var.env} environment"
  
  tags = merge(var.tags, {
    Environment = var.env
    Service     = "monitoring"
    Component   = "grafana"
  })
}

# Generate a secure password for Grafana admin
resource "random_password" "grafana_admin" {
  count   = var.enable_monitoring && var.grafana_use_secrets_manager ? 1 : 0
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret_version" "grafana_admin_password" {
  count     = var.enable_monitoring && var.grafana_use_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.grafana_admin_password[0].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_admin[0].result
  })
}

# SecretProviderClass for Grafana admin password
resource "kubernetes_manifest" "grafana_secret_provider_class" {
  count = var.enable_monitoring && var.grafana_use_secrets_manager ? 1 : 0
  
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "grafana-admin-password"
      namespace = local.monitoring_namespace
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName = aws_secretsmanager_secret.grafana_admin_password[0].name
            objectType = "secretsmanager"
            jmesPath = [
              {
                path = "username"
                objectAlias = "admin-user"
              },
              {
                path = "password"
                objectAlias = "admin-password"
              }
            ]
          }
        ])
      }
      secretObjects = [
        {
          secretName = "grafana-admin-secret"
          type       = "Opaque"
          data = [
            {
              objectName = "admin-password"
              key        = "admin-password"
            },
            {
              objectName = "admin-user"
              key        = "admin-user"
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [aws_secretsmanager_secret_version.grafana_admin_password]
}

# Alternative: Create Kubernetes secret directly from AWS Secrets Manager
# This provides a more reliable approach than CSI volume mounts for Helm charts
resource "kubernetes_secret" "grafana_admin_secret" {
  count = var.enable_monitoring && var.grafana_use_secrets_manager ? 1 : 0

  metadata {
    name      = "grafana-admin-secret"
    namespace = local.monitoring_namespace
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin[0].result
  }

  type = "Opaque"
  
  depends_on = [
    kubernetes_namespace.monitoring,
    random_password.grafana_admin
  ]
}

# Data source to get public subnets for ALB
data "aws_subnets" "public" {
  count = var.enable_monitoring && var.enable_grafana_ingress ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

locals {
  monitoring_namespace = "monitoring"
  # Create comma-separated list of public subnet IDs for ALB
  public_subnets_string = var.enable_monitoring && var.enable_grafana_ingress && length(data.aws_subnets.public) > 0 ? join(",", data.aws_subnets.public[0].ids) : ""
}

# IAM role for Prometheus to access CloudWatch
resource "aws_iam_role" "prometheus_cloudwatch" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.eks_name}-prometheus-cloudwatch-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.openid_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:monitoring:prometheus-kube-prometheus-prometheus"
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "prometheus_cloudwatch" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.eks_name}-prometheus-cloudwatch-${var.env}"
  role  = aws_iam_role.prometheus_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListDashboards"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Kube Prometheus Stack
resource "helm_release" "kube_prometheus_stack" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = local.monitoring_namespace
  version    = var.prometheus_stack_version
  
  # Standard timeout - fail fast to identify issues quickly
  timeout         = 300   # 5 minutes - standard timeout
  wait            = true  # Wait for resources to be ready
  wait_for_jobs   = true  # Wait for any jobs to complete
  
  # Handle upgrades gracefully
  force_update    = false
  recreate_pods   = false
  
  # Depend on the monitoring namespace created in 6-pod-security.tf
  depends_on = [kubernetes_namespace.monitoring]

  values = [
    yamlencode({
      # Prometheus Configuration
      prometheus = {
        prometheusSpec = {
          serviceAccount = {
            annotations = {
              "eks.amazonaws.com/role-arn" = var.enable_monitoring ? aws_iam_role.prometheus_cloudwatch[0].arn : ""
            }
          }
          retention = var.prometheus_retention
          retentionSize = var.prometheus_retention_size
          storageSpec = var.prometheus_storage_enabled ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.prometheus_storage_class
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          } : null
          resources = {
            requests = {
              memory = "2Gi"
              cpu = "500m"
            }
            limits = {
              memory = "4Gi"
              cpu = "1000m"
            }
          }
        }
      }
      
      # Grafana Configuration  
      grafana = {
        # Use secret from AWS Secrets Manager when enabled, otherwise use variable
        adminPassword = var.grafana_use_secrets_manager ? null : var.grafana_admin_password
        admin = var.grafana_use_secrets_manager ? {
          existingSecret = "grafana-admin-secret"
          userKey = "admin-user"
          passwordKey = "admin-password"
        } : null
        
        # Mount AWS Secrets Manager secret via CSI driver - not needed when using direct secret
        extraSecretMounts = []
        
        persistence = {
          enabled = var.grafana_persistence_enabled
          storageClassName = var.grafana_storage_class
          size = var.grafana_storage_size
        }
        service = {
          type = var.grafana_service_type
          annotations = var.grafana_service_type == "LoadBalancer" ? {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          } : {}
        }
        ingress = {
          enabled = var.enable_grafana_ingress
          ingressClassName = var.enable_grafana_ingress ? "alb" : null
          annotations = var.enable_grafana_ingress ? {
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/certificate-arn" = var.ssl_certificate_arn
            "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/ssl-redirect" = "443"
            "alb.ingress.kubernetes.io/subnets" = local.public_subnets_string
            "external-dns.alpha.kubernetes.io/hostname" = var.grafana_hostname
          } : {}
          hosts = var.enable_grafana_ingress && var.grafana_hostname != "" ? [
            var.grafana_hostname
          ] : []
          path = "/"
          tls = var.enable_grafana_ingress && var.grafana_hostname != "" ? [
            {
              hosts = [var.grafana_hostname]
            }
          ] : []
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu = "200m"
          }
        }
      }
      
      # AlertManager Configuration
      alertmanager = {
        alertmanagerSpec = {
          storage = var.alertmanager_storage_enabled ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.alertmanager_storage_class
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          } : null
          resources = {
            requests = {
              memory = "256Mi"
              cpu = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu = "200m"
            }
          }
        }
      }
      
      # Node Exporter Configuration
      nodeExporter = {
        enabled = true
      }
      
      # Kube State Metrics
      kubeStateMetrics = {
        enabled = true
      }
      
      # Default rules and dashboards
      defaultRules = {
        create = true
        rules = {
          etcd = true
          general = true
          k8s = true
          kubeApiserver = true
          kubeApiserverAvailability = true
          kubeApiserverSlos = true
          kubelet = true
          kubePrometheusGeneral = true
          kubePrometheusNodeRecording = true
          kubernetesApps = true
          kubernetesResources = true
          kubernetesStorage = true
          kubernetesSystem = true
          node = true
          nodeExporterAlerting = true
          nodeExporterRecording = true
          prometheus = true
          prometheusOperator = true
        }
      }
    })
  ]

  # No explicit dependency needed as namespace is created in 6-pod-security.tf
}

# CloudWatch Exporter for AWS metrics (optional)
resource "helm_release" "cloudwatch_exporter" {
  count      = var.enable_monitoring && var.enable_cloudwatch_exporter ? 1 : 0
  name       = "prometheus-cloudwatch-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-cloudwatch-exporter"
  namespace  = local.monitoring_namespace
  version    = var.cloudwatch_exporter_version

  values = [
    yamlencode({
      aws = {
        region = var.aws_region
        role_arn = aws_iam_role.prometheus_cloudwatch[0].arn
      }
      config = yamlencode({
        region = var.aws_region
        period_seconds = var.cloudwatch_metrics_collection_interval
        delay_seconds = 120
        metrics = concat(
          # Always include EKS metrics
          [
            {
              aws_namespace = "AWS/EKS"
              aws_metric_name = "cluster_failed_request_count"
              aws_dimensions = ["ClusterName"]
              aws_statistics = ["Sum", "Average"]
            },
            {
              aws_namespace = "AWS/EKS" 
              aws_metric_name = "cluster_request_total_count"
              aws_dimensions = ["ClusterName"]
              aws_statistics = ["Sum", "Average"]
            }
          ],
          # Conditional EC2 metrics
          var.enable_ec2_detailed_monitoring ? [
            {
              aws_namespace = "AWS/EC2"
              aws_metric_name = "CPUUtilization"
              aws_dimensions = ["InstanceId"]
              aws_statistics = ["Average", "Maximum"]
            },
            {
              aws_namespace = "AWS/EC2"
              aws_metric_name = "NetworkIn"
              aws_dimensions = ["InstanceId"]
              aws_statistics = ["Sum", "Average"]
            },
            {
              aws_namespace = "AWS/EC2"
              aws_metric_name = "NetworkOut"
              aws_dimensions = ["InstanceId"]
              aws_statistics = ["Sum", "Average"]
            },
            {
              aws_namespace = "AWS/EC2"
              aws_metric_name = "DiskReadBytes"
              aws_dimensions = ["InstanceId"]
              aws_statistics = ["Sum", "Average"]
            },
            {
              aws_namespace = "AWS/EC2"
              aws_metric_name = "DiskWriteBytes"
              aws_dimensions = ["InstanceId"]
              aws_statistics = ["Sum", "Average"]
            }
          ] : [],
          # Conditional ALB metrics
          var.enable_alb_monitoring ? [
            {
              aws_namespace = "AWS/ApplicationELB"
              aws_metric_name = "RequestCount"
              aws_dimensions = ["LoadBalancer"]
              aws_statistics = ["Sum"]
            },
            {
              aws_namespace = "AWS/ApplicationELB"
              aws_metric_name = "TargetResponseTime"
              aws_dimensions = ["LoadBalancer"]
              aws_statistics = ["Average"]
            },
            {
              aws_namespace = "AWS/ApplicationELB"
              aws_metric_name = "HTTPCode_Target_2XX_Count"
              aws_dimensions = ["LoadBalancer"]
              aws_statistics = ["Sum"]
            },
            {
              aws_namespace = "AWS/ApplicationELB"
              aws_metric_name = "HTTPCode_Target_4XX_Count"
              aws_dimensions = ["LoadBalancer"]
              aws_statistics = ["Sum"]
            },
            {
              aws_namespace = "AWS/ApplicationELB"
              aws_metric_name = "HTTPCode_Target_5XX_Count"
              aws_dimensions = ["LoadBalancer"]
              aws_statistics = ["Sum"]
            }
          ] : [],
          # Conditional NAT Gateway metrics
          var.enable_nat_gateway_monitoring ? [
            {
              aws_namespace = "AWS/NATGateway"
              aws_metric_name = "BytesInFromDestination"
              aws_dimensions = ["NatGatewayId"]
              aws_statistics = ["Sum"]
            },
            {
              aws_namespace = "AWS/NATGateway"
              aws_metric_name = "BytesOutToDestination"
              aws_dimensions = ["NatGatewayId"]
              aws_statistics = ["Sum"]
            }
          ] : [],
          # Conditional Route53 metrics
          var.enable_route53_monitoring ? [
            {
              aws_namespace = "AWS/Route53"
              aws_metric_name = "QueryCount"
              aws_dimensions = ["HostedZoneId"]
              aws_statistics = ["Sum"]
            }
          ] : [],
          # CloudWatch Logs metrics
          [
            {
              aws_namespace = "AWS/Logs"
              aws_metric_name = "IncomingLogEvents"
              aws_dimensions = ["LogGroupName"]
              aws_statistics = ["Sum"]
            }
          ]
        )
      })
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_cloudwatch[0].arn
        }
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

# AWS Services Dashboard ConfigMap for Grafana
resource "kubernetes_config_map" "aws_dashboards" {
  count = var.enable_monitoring && var.enable_aws_service_dashboards ? 1 : 0
  
  metadata {
    name      = "aws-dashboards"
    namespace = local.monitoring_namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "aws-overview.json" = jsonencode({
      dashboard = {
        id = null
        title = "AWS Infrastructure Overview"
        tags = ["aws", "infrastructure"]
        timezone = "browser"
        panels = [
          {
            id = 1
            title = "EKS Cluster Request Rate"
            type = "graph"
            targets = [
              {
                expr = "rate(aws_eks_cluster_request_total_count_sum[5m])"
                legendFormat = "{{cluster_name}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 0 }
          },
          {
            id = 2
            title = "EC2 CPU Utilization"
            type = "graph"
            targets = [
              {
                expr = "aws_ec2_cpuutilization_average"
                legendFormat = "{{instance_id}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 0 }
          },
          {
            id = 3
            title = "ALB Request Count"
            type = "graph"
            targets = [
              {
                expr = "rate(aws_applicationelb_request_count_sum[5m])"
                legendFormat = "{{load_balancer}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 8 }
          },
          {
            id = 4
            title = "ALB Response Time"
            type = "graph"
            targets = [
              {
                expr = "aws_applicationelb_target_response_time_average"
                legendFormat = "{{load_balancer}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 8 }
          }
        ]
        time = {
          from = "now-1h"
          to = "now"
        }
        refresh = "30s"
      }
    })
    
    "aws-networking.json" = jsonencode({
      dashboard = {
        id = null
        title = "AWS Networking Metrics"
        tags = ["aws", "networking"]
        timezone = "browser"
        panels = [
          {
            id = 1
            title = "NAT Gateway Bytes In"
            type = "graph"
            targets = [
              {
                expr = "rate(aws_natgateway_bytes_in_from_destination_sum[5m])"
                legendFormat = "{{nat_gateway_id}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 0 }
          },
          {
            id = 2
            title = "NAT Gateway Bytes Out"
            type = "graph"
            targets = [
              {
                expr = "rate(aws_natgateway_bytes_out_to_destination_sum[5m])"
                legendFormat = "{{nat_gateway_id}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 0 }
          },
          {
            id = 3
            title = "Route53 Query Count"
            type = "graph"
            targets = [
              {
                expr = "rate(aws_route53_query_count_sum[5m])"
                legendFormat = "{{hosted_zone_id}}"
              }
            ]
            gridPos = { h = 8, w = 24, x = 0, y = 8 }
          }
        ]
        time = {
          from = "now-1h"
          to = "now"
        }
        refresh = "30s"
      }
    })
  }
}
