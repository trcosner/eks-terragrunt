# External DNS for automatic Route53 DNS management
# Automatically creates DNS records for Kubernetes services with ingress

data "aws_iam_policy_document" "external_dns" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  count              = var.enable_external_dns ? 1 : 0
  name               = "${var.eks_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  policy_arn = var.external_dns_policy_arn
  role       = aws_iam_role.external_dns[0].name
}

resource "helm_release" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_version
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[0].arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = "us-east-1"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }

  set {
    name  = "zoneIdFilters[0]"
    value = var.hosted_zone_id
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "sources[0]"
    value = "service"
  }

  set {
    name  = "sources[1]"
    value = "ingress"
  }

  set {
    name  = "txtOwnerId"
    value = var.eks_name
  }

  set {
    name  = "txtPrefix"
    value = "external-dns-"
  }

  set {
    name  = "logLevel"
    value = "info"
  }

  set {
    name  = "interval"
    value = "1m"
  }

  # Resource specifications to comply with resource quotas
  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "128Mi"
  }

  depends_on = [
    aws_iam_role_policy_attachment.external_dns
  ]
}
