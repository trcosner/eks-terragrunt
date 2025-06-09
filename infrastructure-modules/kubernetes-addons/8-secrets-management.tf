# AWS Secrets Manager Integration for EKS
# Implements AWS Secrets Store CSI Driver for secure secrets management

# Install AWS Secrets Store CSI Driver
resource "helm_release" "secrets_store_csi_driver" {
  count = var.enable_secrets_management ? 1 : 0

  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = var.secrets_store_csi_driver_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      syncSecret = {
        enabled = true
      }
      enableSecretRotation = true
    })
  ]
}

# Install AWS Provider for Secrets Store CSI Driver
resource "helm_release" "secrets_store_csi_driver_aws" {
  count = var.enable_secrets_management ? 1 : 0

  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.aws_secrets_provider_version
  namespace  = "kube-system"

  depends_on = [helm_release.secrets_store_csi_driver]
}

# IAM Role for Secrets Manager access
resource "aws_iam_role" "secrets_manager_role" {
  count = var.enable_secrets_management ? 1 : 0

  name = "${var.eks_name}-secrets-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.openid_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:production:secrets-manager-sa"
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.eks_name}-secrets-manager-role"
  }
}

# Attach bootstrap policy to role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy" {
  count = var.enable_secrets_management ? 1 : 0

  role       = aws_iam_role.secrets_manager_role[0].name
  policy_arn = var.secrets_manager_policy_arn
}

# Service Account for Secrets Manager
resource "kubernetes_service_account" "secrets_manager_sa" {
  count = var.enable_secrets_management ? 1 : 0

  metadata {
    name      = "secrets-manager-sa"
    namespace = "production"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.secrets_manager_role[0].arn
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# Example SecretProviderClass for applications to use
# Note: This resource is disabled during initial deployment to avoid CRD dependency issues
# After the CSI driver is installed, set create_example_secret_provider_class = true
resource "kubernetes_manifest" "example_secret_provider_class" {
  count = var.enable_secrets_management && var.create_example_secret_provider_class ? 1 : 0
  
  depends_on = [
    helm_release.secrets_store_csi_driver,
    helm_release.secrets_store_csi_driver_aws,
    kubernetes_namespace.production
  ]

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "app-secrets"
      namespace = "production"
    }
    spec = {
      provider = "aws"
      parameters = {
        region = data.aws_region.current.name
        objects = yamlencode([
          {
            objectName = "${var.env}/database/password"
            objectType = "secretsmanager"
            jmesPath = [
              {
                path        = "password"
                objectAlias = "db-password"
              }
            ]
          },
          {
            objectName = "${var.env}/api/keys"
            objectType = "secretsmanager"
            jmesPath = [
              {
                path        = "api_key"
                objectAlias = "api-key"
              }
            ]
          }
        ])
      }
      secretObjects = [
        {
          secretName = "app-secrets"
          type       = "Opaque"
          data = [
            {
              objectName = "db-password"
              key        = "database-password"
            },
            {
              objectName = "api-key"
              key        = "api-key"
            }
          ]
        }
      ]
    }
  }
}

# Data sources for AWS info
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
