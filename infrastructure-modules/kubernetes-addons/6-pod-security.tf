# Pod Security Standards Implementation
# This implements Kubernetes Pod Security Standards to enforce security policies

# Create production namespace with restricted pod security
resource "kubernetes_namespace" "production" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name = "production"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Create staging namespace with baseline pod security (more permissive for testing)
resource "kubernetes_namespace" "staging_apps" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name = "staging-apps"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Create development namespace with privileged access (for testing)
resource "kubernetes_namespace" "development" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name = "development"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }
}

# Create monitoring namespace for observability tools
# Uses privileged security to allow node-exporter and other monitoring components
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }
}

# Default network policy template for applications
resource "kubernetes_manifest" "pod_security_policy_template" {
  count = var.enable_pod_security_standards ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "pod-security-policy-template"
      namespace = "kube-system"
    }
    data = {
      "restricted-policy.yaml" = yamlencode({
        apiVersion = "v1"
        kind       = "Pod"
        metadata = {
          annotations = {
            "pod-security.kubernetes.io/enforce" = "restricted"
          }
        }
        spec = {
          securityContext = {
            runAsNonRoot        = true
            runAsUser          = 1000
            fsGroup            = 2000
            seccompProfile = {
              type = "RuntimeDefault"
            }
          }
          containers = [{
            name  = "example"
            image = "nginx:latest"
            securityContext = {
              allowPrivilegeEscalation = false
              readOnlyRootFilesystem   = true
              runAsNonRoot             = true
              runAsUser                = 1000
              capabilities = {
                drop = ["ALL"]
              }
            }
            resources = {
              limits = {
                cpu    = "500m"
                memory = "512Mi"
              }
              requests = {
                cpu    = "100m"
                memory = "128Mi"
              }
            }
          }]
        }
      })
    }
  }
}

# Resource Quotas for Namespaces
# Default namespace resource quota
resource "kubernetes_resource_quota" "default" {
  count = var.enable_resource_quotas ? 1 : 0

  metadata {
    name      = "default-quota"
    namespace = "default"
  }

  spec {
    hard = {
      "requests.cpu"               = var.default_namespace_cpu_requests
      "requests.memory"            = var.default_namespace_memory_requests
      "limits.cpu"                 = var.default_namespace_cpu_limits
      "limits.memory"              = var.default_namespace_memory_limits
      "pods"                       = var.default_namespace_pod_limit
      "persistentvolumeclaims"     = "5"
      "services"                   = "5"
      "secrets"                    = "10"
      "configmaps"                 = "10"
    }
  }
}

# Kube-system namespace resource quota
resource "kubernetes_resource_quota" "kube_system" {
  count = var.enable_resource_quotas ? 1 : 0

  metadata {
    name      = "kube-system-quota"
    namespace = "kube-system"
  }

  spec {
    hard = {
      "requests.cpu"               = var.kube_system_namespace_cpu_requests
      "requests.memory"            = var.kube_system_namespace_memory_requests
      "limits.cpu"                 = var.kube_system_namespace_cpu_limits
      "limits.memory"              = var.kube_system_namespace_memory_limits
      "pods"                       = var.kube_system_namespace_pod_limit
      "persistentvolumeclaims"     = "10"
      "services"                   = "10"
      "secrets"                    = "20"
      "configmaps"                 = "20"
    }
  }
}
