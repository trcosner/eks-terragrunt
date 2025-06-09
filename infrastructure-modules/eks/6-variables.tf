variable "env" {
  description = "Environment name, e.g. staging, production"
  type        = string
}

variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Version of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_iam_policies" {
  description = "Map of IAM policies to attach to the EKS node group role"
  type        = map(any)
  default     = {
    1 = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    2 = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    3 = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    4 = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "node_groups" {
  description = "Map of EKS node groups with their configurations"
  type = map(object({
    capacity_type = string
    instance_types = list(string)
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
  }))
  default = {}
}

variable "enable_irsa" {
  description = "Determines whether to create an Open ID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}