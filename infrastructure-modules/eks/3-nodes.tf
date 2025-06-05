resource "aws_eks_node_group" "this" {
    for_each = var.node_groups
    cluster_name    = aws_eks_cluster.this.name
    node_group_name = each.key
    node_role_arn   = aws_iam_role.nodes.arn

    subnet_ids      = var.subnet_ids

    capacity_type = each.value.capacity_type
    instance_types = each.value.instance_types
    
    scaling_config {
        desired_size = each.value.scaling_config.desired_size
        max_size     = each.value.scaling_config.max_size
        min_size     = each.value.scaling_config.min_size
    }

    update_config {
        max_unavailable = 1
    }

    labels = {
        role = each.key
    }

    tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${aws_eks_cluster.this.name}" = "owned"
    }

    depends_on = [
        aws_iam_role_policy_attachment.nodes,
    ]
}