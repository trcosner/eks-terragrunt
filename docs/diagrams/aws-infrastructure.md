# AWS Infrastructure Architecture

This diagram shows the complete AWS infrastructure setup for the EKS Terragrunt project, including multi-environment deployment with shared resources.

```mermaid
graph TB
    %% External Access
    INTERNET[🌐 Internet]
    USERS[👥 Users]
    
    %% AWS Account Structure
    subgraph "AWS Account (241947254546)"
        %% Route53 DNS
        subgraph "🌐 Route53 DNS"
            R53[📍 Route53 Hosted Zone<br/>cosner.cloud<br/>Z02294761J2DBSVSKN3NU]
            DNS_RECORDS[📝 DNS Records<br/>Auto-managed by External DNS]
        end
        
        %% Global Shared Resources (Bootstrap)
        subgraph "🔧 Global Resources (Bootstrap)"
            S3[🗄️ S3 Bucket<br/>eks-terragrunt-terraform-state<br/>Terraform State Storage]
            DDB[🔒 DynamoDB Table<br/>terraform-state-lock<br/>State Locking]
            IAM_EXT[🔑 IAM Policy<br/>External DNS<br/>Route53 Permissions]
            IAM_LB[🔑 IAM Policy<br/>Load Balancer Controller<br/>ELB Permissions]
            IAM_SM[🔑 IAM Policy<br/>Secrets Manager<br/>GetSecretValue Permissions]
        end
        
        %% Development Environment
        subgraph "🔬 Development Environment (us-east-1)"
            %% VPC Network
            subgraph "🏗️ VPC (eks-terragrunt-dev-vpc)"
                IGW_DEV[🚪 Internet Gateway]
                
                %% Public Subnets
                subgraph "🌐 Public Subnets (Load Balancers)"
                    PUB_DEV_1A[📍 Public Subnet 1<br/>us-east-1a<br/>10.0.1.0/24]
                    PUB_DEV_1B[📍 Public Subnet 2<br/>us-east-1b<br/>10.0.2.0/24]
                    PUB_DEV_1C[📍 Public Subnet 3<br/>us-east-1c<br/>10.0.3.0/24]
                end
                
                %% NAT Gateways
                NAT_DEV_1A[🔄 NAT Gateway<br/>us-east-1a]
                NAT_DEV_1B[🔄 NAT Gateway<br/>us-east-1b]
                NAT_DEV_1C[🔄 NAT Gateway<br/>us-east-1c]
                
                %% Private Subnets
                subgraph "🔒 Private Subnets (EKS Nodes)"
                    PRIV_DEV_1A[📍 Private Subnet 1<br/>us-east-1a<br/>10.0.11.0/24<br/>EKS Worker Nodes]
                    PRIV_DEV_1B[📍 Private Subnet 2<br/>us-east-1b<br/>10.0.12.0/24<br/>EKS Worker Nodes]
                    PRIV_DEV_1C[📍 Private Subnet 3<br/>us-east-1c<br/>10.0.13.0/24<br/>EKS Worker Nodes]
                end
            end
            
            %% EKS Cluster Dev
            subgraph "☸️ EKS Cluster (eks-terragrunt-dev)"
                CONTROL_DEV[🎛️ EKS Control Plane<br/>Managed by AWS<br/>Kubernetes API v1.28]
                
                subgraph "🖥️ Managed Node Groups"
                    NG_DEV_1A[🖥️ Node Group AZ-A<br/>t3.medium<br/>Auto Scaling: 1-3]
                    NG_DEV_1B[🖥️ Node Group AZ-B<br/>t3.medium<br/>Auto Scaling: 1-3]
                    NG_DEV_1C[🖥️ Node Group AZ-C<br/>t3.medium<br/>Auto Scaling: 1-3]
                end
            end
            
            %% Load Balancer Dev
            ALB_DEV[⚖️ Application Load Balancer<br/>Internet-facing<br/>Created by AWS LB Controller]
        end
        
        %% Staging Environment
        subgraph "🎭 Staging Environment (us-east-1)"
            %% Simplified representation
            VPC_STAGING[🏗️ VPC (eks-terragrunt-staging-vpc)<br/>Similar Multi-AZ Setup<br/>6 Subnets + 3 NAT Gateways]
            EKS_STAGING[☸️ EKS Cluster (eks-terragrunt-staging)<br/>Control Plane + Node Groups<br/>Multi-AZ Configuration]
            ALB_STAGING[⚖️ Application Load Balancer<br/>Internet-facing]
        end
        
        %% AWS Managed Services
        subgraph "☁️ AWS Managed Services"
            SM[🔐 AWS Secrets Manager<br/>Application Secrets<br/>Database Credentials<br/>API Keys]
            CW[📊 CloudWatch<br/>Container Insights<br/>Log Groups<br/>Metrics]
            ECR[📦 Elastic Container Registry<br/>Container Images]
            ACM[🔒 AWS Certificate Manager<br/>SSL/TLS Certificates<br/>*.cosner.cloud]
        end
    end
    
    %% Traffic Flow Connections
    INTERNET --> R53
    USERS --> R53
    R53 --> ALB_DEV
    R53 --> ALB_STAGING
    
    %% Network Connections Dev
    INTERNET --> IGW_DEV
    IGW_DEV --> PUB_DEV_1A
    IGW_DEV --> PUB_DEV_1B
    IGW_DEV --> PUB_DEV_1C
    
    PUB_DEV_1A --> NAT_DEV_1A
    PUB_DEV_1B --> NAT_DEV_1B
    PUB_DEV_1C --> NAT_DEV_1C
    
    NAT_DEV_1A --> PRIV_DEV_1A
    NAT_DEV_1B --> PRIV_DEV_1B
    NAT_DEV_1C --> PRIV_DEV_1C
    
    %% EKS Connections
    CONTROL_DEV --> NG_DEV_1A
    CONTROL_DEV --> NG_DEV_1B
    CONTROL_DEV --> NG_DEV_1C
    
    %% Load Balancer to Nodes
    ALB_DEV --> NG_DEV_1A
    ALB_DEV --> NG_DEV_1B
    ALB_DEV --> NG_DEV_1C
    
    %% AWS Service Integration
    NG_DEV_1A -.-> SM
    NG_DEV_1B -.-> SM
    NG_DEV_1C -.-> SM
    NG_DEV_1A -.-> CW
    NG_DEV_1B -.-> CW
    NG_DEV_1C -.-> CW
    
    %% Staging Connections
    ALB_STAGING --> EKS_STAGING
    EKS_STAGING -.-> SM
    EKS_STAGING -.-> CW
    
    %% Styling
    style INTERNET fill:#e1f5fe
    style R53 fill:#c8e6c9
    style S3 fill:#ffcdd2
    style DDB fill:#ffcdd2
    style CONTROL_DEV fill:#bbdefb
    style EKS_STAGING fill:#bbdefb
    style SM fill:#fff3e0
    style CW fill:#fff3e0
    style ALB_DEV fill:#f3e5f5
    style ALB_STAGING fill:#f3e5f5
```

## Infrastructure Components

### 🏗️ **Network Architecture**
- **Multi-AZ Deployment**: 3 Availability Zones (us-east-1a, us-east-1b, us-east-1c)
- **VPC Separation**: Isolated VPCs for dev and staging environments
- **Public Subnets**: Host NAT Gateways and Load Balancers
- **Private Subnets**: Host EKS worker nodes (secure by design)
- **High Availability**: 3 NAT Gateways for redundancy (one per AZ)

### ☸️ **EKS Clusters**
- **Managed Control Plane**: AWS-managed Kubernetes API servers
- **Managed Node Groups**: Auto-scaling worker nodes across 3 AZs
- **Instance Type**: t3.medium (cost-optimized for development/staging)
- **Scaling**: 1-3 nodes per AZ based on demand

### 🔧 **Shared Resources (Bootstrap)**
- **Terraform State**: Centralized in S3 with DynamoDB locking
- **IAM Policies**: Shared across environments for consistency
- **Route53**: Single hosted zone for all environments

### 🌐 **Traffic Flow**
1. Internet traffic → Route53 DNS resolution
2. Route53 → Application Load Balancers (per environment)
3. ALB → EKS worker nodes across multiple AZs
4. Worker nodes → Application pods with security policies

### 💰 **Cost Optimization**
- **NAT Gateways**: High availability but significant cost ($45/month per environment)
- **EKS Control Plane**: $73/month per environment
- **Worker Nodes**: Auto-scaling to minimize costs during low usage
- **Single Route53 Zone**: Shared across environments