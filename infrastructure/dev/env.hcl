locals {
    env = "dev"
    region = "us-east-1"
    
    # Project configuration
    project_name = "eks-terragrunt-demo"
    cost_center = "engineering"
    owner = "devops-team"
    
    # Environment-specific sizing for dev
    node_instance_types = ["t3a.large"]  # Smaller instances for dev
    min_nodes = 1
    max_nodes = 3
    
    # Monitoring configuration
    enable_monitoring = true
    
    tags = {
        Environment = "dev"
        Project     = "eks-terragrunt-demo"
        ManagedBy   = "terragrunt"
        CostCenter  = "engineering"
        Owner       = "devops-team"
    }
}