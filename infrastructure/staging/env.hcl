locals {
    env = "staging"
    region = "us-east-1"
    
    # Project configuration
    project_name = "eks-terragrunt-demo"
    cost_center = "engineering"
    owner = "devops-team"
    
    # Environment-specific sizing for staging
    node_instance_types = ["t3a.xlarge"]  # Larger instances for staging
    min_nodes = 2
    max_nodes = 5
    
    # Monitoring configuration
    enable_monitoring = true
    
    tags = {
        Environment = "staging"
        Project     = "eks-terragrunt-demo"
        ManagedBy   = "terragrunt"
        CostCenter  = "engineering"
        Owner       = "devops-team"
    }
}