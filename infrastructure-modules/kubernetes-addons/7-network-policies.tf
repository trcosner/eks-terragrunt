# Network Policies for EKS Security
# Implements a balanced approach: secure by default, practical for public-facing applications

# Default deny-all policy for production namespace
resource "kubernetes_network_policy" "production_default_deny" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = "production"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [kubernetes_namespace.production]
}

# Allow ingress from AWS Load Balancer Controller to production apps
resource "kubernetes_network_policy" "production_allow_alb_ingress" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-alb-ingress"
    namespace = "production"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/component" = "web"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "aws-load-balancer-controller"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = "80"
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }

    # Allow ingress from internet (for ALB targets)
    ingress {
      ports {
        protocol = "TCP"
        port     = "80"
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# Allow production apps to communicate with each other
resource "kubernetes_network_policy" "production_allow_internal" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-internal-communication"
    namespace = "production"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "production"
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "production"
          }
        }
      }
    }

    # Allow DNS resolution
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            k8s-app = "kube-dns"
          }
        }
      }
      ports {
        protocol = "UDP"
        port     = "53"
      }
      ports {
        protocol = "TCP"
        port     = "53"
      }
    }

    # Allow egress to internet (for API calls, external services)
    egress {
      ports {
        protocol = "TCP"
        port     = "80"
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# Allow monitoring namespace to scrape metrics from production
resource "kubernetes_network_policy" "production_allow_monitoring" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-monitoring-ingress"
    namespace = "production"
  }

  spec {
    pod_selector {
      match_labels = {
        "monitoring" = "enabled"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "monitoring"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = "9090"  # Prometheus metrics
      }
      ports {
        protocol = "TCP"
        port     = "8080"  # Health checks
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# Staging namespace - more permissive for testing
resource "kubernetes_network_policy" "staging_allow_all" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-all-staging"
    namespace = "staging-apps"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {}  # Allow all ingress
    egress {}   # Allow all egress
  }

  depends_on = [kubernetes_namespace.staging_apps]
}

# Development namespace - fully permissive
resource "kubernetes_network_policy" "development_allow_all" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-all-development"
    namespace = "development"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {}  # Allow all ingress
    egress {}   # Allow all egress
  }

  depends_on = [kubernetes_namespace.development]
}

# Monitoring namespace network policy
resource "kubernetes_network_policy" "monitoring_policy" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "monitoring-network-policy"
    namespace = "monitoring"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    # Allow monitoring tools to scrape metrics from all namespaces
    egress {}

    # Allow ingress for Grafana dashboards
    ingress {
      ports {
        protocol = "TCP"
        port     = "3000"  # Grafana
      }
      ports {
        protocol = "TCP"
        port     = "9090"  # Prometheus
      }
    }

    # Allow internal communication within monitoring namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "monitoring"
          }
        }
      }
    }
  }

  # Monitoring namespace is created in 6-pod-security.tf
}
