data "aws_eks_cluster" "kubernetes" {
    name = var.eks_name
}

data "aws_eks_cluster_auth" "kubernetes" {
    name = var.eks_name
}

provider "kubernetes" {
    host                   = data.aws_eks_cluster.kubernetes.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.kubernetes.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.kubernetes.token
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", var.eks_name]
        command     = "aws"
    }
}
