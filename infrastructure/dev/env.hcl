locals {
    env = "dev"
    
    tags = {
        Environment = "dev"
        Project     = "eks-terragrunt-demo"
        ManagedBy   = "terragrunt"
    }
}