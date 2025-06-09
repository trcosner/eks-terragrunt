# EKS Cluster Internal Architecture

This diagram shows the internal architecture of the EKS clusters, including security policies, namespaces, add-ons, and service integrations.

```mermaid
graph TB
    %% External Traffic Entry
    INTERNET[🌐 Internet Traffic]
    DNS[🌐 DNS: *.cosner.cloud]
    
    %% EKS Control Plane
    subgraph "☁️ EKS Control Plane (AWS Managed)"
        API[🎛️ Kubernetes API Server<br/>Authentication & Authorization]
        ETCD[💾 etcd Database<br/>Cluster State Storage]
        SCHED[📋 Scheduler<br/>Pod Placement]
        CM[🔄 Controller Manager<br/>Resource Controllers]
    end
    
    %% Worker Nodes Multi-AZ
    subgraph "🖥️ Worker Nodes (Multi-AZ)"
        subgraph "📍 us-east-1a"
            NODE1[🖥️ Worker Node 1<br/>t3.medium<br/>kubelet, kube-proxy<br/>Container Runtime]
        end
        
        subgraph "📍 us-east-1b"
            NODE2[🖥️ Worker Node 2<br/>t3.medium<br/>kubelet, kube-proxy<br/>Container Runtime]
        end
        
        subgraph "📍 us-east-1c"
            NODE3[🖥️ Worker Node 3<br/>t3.medium<br/>kubelet, kube-proxy<br/>Container Runtime]
        end
    end
    
    %% Application Namespaces with Security Policies
    subgraph "🔒 Secured Application Namespaces"
        subgraph "🔴 production (Pod Security: restricted)"
            PROD_APPS[🚀 Production Applications<br/>• Highest Security<br/>• Non-root containers<br/>• ReadOnly filesystem<br/>• No privileged access]
            SECRET_SA[🔑 secrets-manager-sa<br/>IRSA: AWS Secrets Manager]
        end
        
        subgraph "🟡 staging-apps (Pod Security: baseline)"
            STAGE_APPS[🎭 Staging Applications<br/>• Moderate Security<br/>• Known privilege escalations<br/>• Some host access allowed]
        end
        
        subgraph "🟢 development (Pod Security: privileged)"
            DEV_APPS[🔬 Development Applications<br/>• Relaxed Security<br/>• All operations allowed<br/>• Testing & debugging]
        end
        
        subgraph "📊 monitoring (Pod Security: baseline)"
            MONITOR_APPS[📈 Monitoring Stack<br/>• Future: Prometheus<br/>• Future: Grafana<br/>• Future: AlertManager]
        end
    end
    
    %% System Components
    subgraph "⚙️ kube-system (Core Add-ons)"
        %% Essential Add-ons
        CA[🔄 Cluster Autoscaler<br/>• Node Auto-scaling<br/>• Cost Optimization<br/>• Multi-AZ Awareness]
        
        LBCTRL[⚖️ AWS Load Balancer Controller<br/>• ALB/NLB Management<br/>• Target Group Binding<br/>• SSL Termination]
        
        EXTDNS[🌐 External DNS<br/>• Route53 Integration<br/>• Automatic DNS Records<br/>• Domain: cosner.cloud]
        
        %% Secrets Management
        CSI_DRIVER[🔐 Secrets Store CSI Driver<br/>• Secure Secret Mounting<br/>• Volume Integration<br/>• Rotation Support]
        
        AWS_PROVIDER[☁️ AWS Secrets Provider<br/>• Secrets Manager Integration<br/>• Parameter Store Support<br/>• IRSA Authentication]
        
        %% Core Networking
        VPC_CNI[🔗 VPC CNI<br/>• Pod Networking<br/>• IP Address Management<br/>• Security Groups]
        
        COREDNS[🌐 CoreDNS<br/>• Cluster DNS Resolution<br/>• Service Discovery<br/>• External DNS Forwarding]
        
        KUBE_PROXY[🔀 kube-proxy<br/>• Service Load Balancing<br/>• iptables/IPVS Rules<br/>• Network Policy Enforcement]
    end
    
    %% Network Security Policies
    subgraph "🛡️ Network Security (Network Policies)"
        NP_PROD[🔒 production Policy<br/>• Ingress: ALB Only (Port 80/443)<br/>• Egress: HTTPS + DNS Only<br/>• Default: Deny All]
        
        NP_STAGE[🔓 staging-apps Policy<br/>• Ingress: Allow All<br/>• Egress: Allow All<br/>• Purpose: Development Flexibility]
        
        NP_DEFAULT[❌ default Policy<br/>• Ingress: Deny All<br/>• Egress: Deny All<br/>• Purpose: Secure by Default]
        
        NP_MONITOR[📊 monitoring Policy<br/>• Ingress: Prometheus Scraping<br/>• Egress: External Alerting<br/>• Purpose: Observability]
    end
    
    %% IRSA (IAM Roles for Service Accounts)
    subgraph "🔑 IRSA (Secure AWS Access)"
        IRSA_CA[🔄 cluster-autoscaler SA<br/>→ EC2 Auto Scaling<br/>→ EKS Describe]
        
        IRSA_LB[⚖️ aws-load-balancer-controller SA<br/>→ ELB Full Access<br/>→ EC2 Describe<br/>→ WAF Integration]
        
        IRSA_EXT[🌐 external-dns SA<br/>→ Route53 ChangeResourceRecordSets<br/>→ Route53 List Operations<br/>→ Hosted Zone: cosner.cloud]
        
        IRSA_SEC[🔐 secrets-manager-sa<br/>→ Secrets Manager GetSecretValue<br/>→ Secrets Manager DescribeSecret<br/>→ Account: 241947254546]
    end
    
    %% Storage Classes
    subgraph "💾 Storage & Persistence"
        EBS[📀 EBS CSI Driver<br/>• Persistent Volumes<br/>• Dynamic Provisioning<br/>• Snapshot Support]
        
        GP3[⚡ gp3 Storage Class<br/>• Default Storage<br/>• High IOPS<br/>• Cost Optimized]
        
        SECRET_VOLS[🔐 Secret Volumes<br/>• CSI Secret Store<br/>• AWS Secrets Manager<br/>• Automatic Rotation]
    end
    
    %% External AWS Services
    subgraph "☁️ External AWS Services"
        AWS_SM[🔐 AWS Secrets Manager<br/>• dev/database/password<br/>• dev/api/keys<br/>• staging/database/password]
        
        AWS_R53[🌐 Route53 Hosted Zone<br/>• cosner.cloud<br/>• Automatic A/CNAME Records<br/>• External DNS Management]
        
        AWS_ELB[⚖️ Elastic Load Balancing<br/>• Application Load Balancers<br/>• Target Groups<br/>• Health Checks]
        
        AWS_CW[📊 CloudWatch<br/>• Container Insights<br/>• Log Groups<br/>• Metrics & Alarms]
    end
    
    %% Traffic Flow
    INTERNET --> DNS
    DNS --> AWS_ELB
    AWS_ELB --> LBCTRL
    LBCTRL --> PROD_APPS
    LBCTRL --> STAGE_APPS
    
    %% Control Plane Connections
    API --> NODE1
    API --> NODE2
    API --> NODE3
    
    %% Pod Placement
    NODE1 --> PROD_APPS
    NODE2 --> STAGE_APPS
    NODE3 --> DEV_APPS
    NODE1 --> MONITOR_APPS
    
    %% IRSA Connections
    CA --> IRSA_CA
    LBCTRL --> IRSA_LB
    EXTDNS --> IRSA_EXT
    SECRET_SA --> IRSA_SEC
    
    %% AWS Service Integration
    EXTDNS --> AWS_R53
    SECRET_SA --> AWS_SM
    LBCTRL --> AWS_ELB
    CA --> NODE1
    CA --> NODE2
    CA --> NODE3
    
    %% Storage Integration
    PROD_APPS --> SECRET_VOLS
    SECRET_VOLS --> CSI_DRIVER
    CSI_DRIVER --> AWS_PROVIDER
    AWS_PROVIDER --> AWS_SM
    
    %% Network Policy Application
    NP_PROD -.-> PROD_APPS
    NP_STAGE -.-> STAGE_APPS
    NP_DEFAULT -.-> DEV_APPS
    NP_MONITOR -.-> MONITOR_APPS
    
    %% Styling
    style API fill:#e3f2fd
    style PROD_APPS fill:#ffebee
    style STAGE_APPS fill:#fff8e1
    style DEV_APPS fill:#e8f5e8
    style MONITOR_APPS fill:#f3e5f5
    style EXTDNS fill:#fce4ec
    style CA fill:#fce4ec
    style LBCTRL fill:#fce4ec
    style CSI_DRIVER fill:#e8eaf6
    style AWS_SM fill:#fff3e0
    style AWS_R53 fill:#e0f2f1
    style AWS_ELB fill:#fce4ec
```

## Security Architecture

### 🔒 **Pod Security Standards (Defense in Depth)**
- **Production (Restricted)**: Maximum security - non-root containers, read-only filesystem, no privileged access
- **Staging (Baseline)**: Moderate security - prevents privilege escalation, allows known vulnerabilities  
- **Development (Privileged)**: Minimal restrictions - allows all operations for testing
- **Monitoring (Baseline)**: Moderate security suitable for observability tools

### 🛡️ **Network Policies (Network Segmentation)**
- **Production**: Ingress only from ALB (ports 80/443), egress only HTTPS + DNS
- **Staging**: Permissive for development flexibility
- **Default**: Deny all by default (secure baseline)
- **Monitoring**: Allows Prometheus scraping and external alerting

### 🔑 **IRSA (IAM Roles for Service Accounts)**
- **No Static Credentials**: All AWS access via temporary STS tokens
- **Least Privilege**: Each service account has minimal required permissions
- **Auditable**: All AWS API calls traceable to specific Kubernetes service accounts

## Add-on Services

### ⚙️ **Essential Add-ons**
- **Cluster Autoscaler**: Automatically scales nodes based on pod resource requests
- **AWS Load Balancer Controller**: Manages ALB/NLB for Kubernetes services
- **External DNS**: Automatically manages Route53 DNS records
- **VPC CNI**: Provides pod networking with AWS VPC integration

### 🔐 **Secrets Management**
- **CSI Driver**: Mounts secrets as volumes (not environment variables)
- **AWS Provider**: Integrates with AWS Secrets Manager and Parameter Store
- **Secret Rotation**: Automatic rotation support with volume remounts

### 📊 **Observability (Planned)**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **AlertManager**: Alert routing and notifications
- **Fluent Bit**: Log collection and forwarding to CloudWatch