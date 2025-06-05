data "aws_iam_openid_connect_provider" "this" {
  arn = var.openid_provider_arn
}

data "aws_iam_policy_document" "cluser_autoscaler" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
        test     = "StringEquals"
        variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
        values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
    count = var.enable_cluster_autoscaler ? 1 : 0
  name               = "${var.eks_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluser_autoscaler.json
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name        = "${var.eks_name}-cluster-autoscaler-policy"
  description = "Policy for EKS Cluster Autoscaler"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
        ]
        Resource = "*"
        Effect = "Allow"
      }, {
        Action = [
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect = "Allow"
        Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  version = var.helm_chart_version

  namespace = "kube-system"
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler[0].arn
  } 

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_name
  }

  set {
    name  = "awsRegion"
    value = "us-east-1"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "2m"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "2m"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }
}