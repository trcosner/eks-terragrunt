locals {
    env = "staging"
    
    tags = {
        Environment = "staging"
        Project     = "eks-terragrunt-demo"
        ManagedBy   = "terragrunt"
    }
}