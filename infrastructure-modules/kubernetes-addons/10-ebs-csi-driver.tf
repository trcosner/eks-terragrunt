# EBS CSI Driver for persistent storage
# Required for PersistentVolumeClaims to work with EBS volumes

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  name  = "${var.eks_name}-ebs-csi-driver-${var.env}"

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
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(var.openid_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Custom EBS CSI Driver Policy
resource "aws_iam_policy" "ebs_csi_driver_custom" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  name  = "${var.eks_name}-ebs-csi-driver-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestedRegion" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestedRegion" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeSnapshotName" = "*"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

# Attach the custom EBS CSI policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.enable_ebs_csi_driver ? 1 : 0
  policy_arn = aws_iam_policy.ebs_csi_driver_custom[0].arn
  role       = aws_iam_role.ebs_csi_driver[0].name
}

# EBS CSI Driver Helm chart
resource "helm_release" "ebs_csi_driver" {
  count            = var.enable_ebs_csi_driver ? 1 : 0
  name             = "aws-ebs-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  create_namespace = false
  version          = "2.35.1"

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_driver[0].arn
  }

  set {
    name  = "node.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "node.serviceAccount.name"
    value = "ebs-csi-node-sa"
  }

  set {
    name  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_driver[0].arn
  }

  # Enable volume snapshot functionality
  set {
    name  = "controller.volumeModificationFeature.enabled"
    value = "true"
  }

  set {
    name  = "controller.batching"
    value = "true"
  }

  # Resource limits for better resource management
  set {
    name  = "controller.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "128Mi"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "10m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "40Mi"
  }

  set {
    name  = "node.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "node.resources.limits.memory"
    value = "128Mi"
  }

  set {
    name  = "node.resources.requests.cpu"
    value = "10m"
  }

  set {
    name  = "node.resources.requests.memory"
    value = "40Mi"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}

# Storage class for GP3 volumes (more cost-effective than GP2)
resource "kubernetes_storage_class" "gp3" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [helm_release.ebs_csi_driver]
}

# Remove default annotation from gp2 storage class
resource "kubernetes_annotations" "gp2_not_default" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  
  metadata {
    name = "gp2"
  }
  
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [kubernetes_storage_class.gp3]
}
