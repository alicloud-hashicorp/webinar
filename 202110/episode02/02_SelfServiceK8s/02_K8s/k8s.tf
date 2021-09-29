resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = var.k8s_name
  }
}

resource "kubernetes_service_account" "kubernetes_dashboard" {
  metadata {
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }
}

resource "kubernetes_service" "kubernetes_dashboard" {
  metadata {
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  spec {
    port {
      port        = 443
      target_port = "8443"
    }

    selector = {
      k8s-app = var.k8s_name
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_secret" "kubernetes_dashboard_certs" {
  metadata {
    name      = "kubernetes-dashboard-certs"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_csrf" {
  metadata {
    name      = "kubernetes-dashboard-csrf"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_key_holder" {
  metadata {
    name      = "kubernetes-dashboard-key-holder"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "kubernetes_dashboard_settings" {
  metadata {
    name      = "kubernetes-dashboard-settings"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }
}

resource "kubernetes_role" "kubernetes_dashboard" {
  metadata {
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  rule {
    verbs          = ["get", "update", "delete"]
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [kubernetes_secret.kubernetes_dashboard_key_holder.metadata.0.name, kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name, kubernetes_secret.kubernetes_dashboard_csrf.metadata.0.name]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = [kubernetes_config_map.kubernetes_dashboard_settings.metadata.0.name]
  }

  rule {
    verbs          = ["proxy"]
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster", kubernetes_service.dashboard_metrics_scraper.metadata.0.name]
  }

  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:", kubernetes_service.dashboard_metrics_scraper.metadata.0.name, "http:${kubernetes_service.dashboard_metrics_scraper.metadata.0.name}"]
  }
}

resource "kubernetes_cluster_role" "kubernetes_dashboard" {
  metadata {
    name = var.k8s_name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
  }
}

resource "kubernetes_role_binding" "kubernetes_dashboard" {
  metadata {
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.k8s_name
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard" {
  metadata {
    name = var.k8s_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.k8s_name
  }
}

resource "kubernetes_deployment" "kubernetes_dashboard" {
  metadata {
    name      = var.k8s_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.k8s_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = var.k8s_name
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = var.k8s_name
        }
      }

      spec {
        volume {
          name = kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name

          secret {
            secret_name = kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name
          }
        }

        volume {
          name = "tmp-volume"
        }

        container {
          name  = "kubernetes-dashboard"
          image = "kubernetesui/dashboard:${var.dashboard_tag}"
          args  = ["--auto-generate-certificates", "--namespace=${var.k8s_name}"]

          port {
            container_port = 8443
            protocol       = "TCP"
          }

          volume_mount {
            name       = kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name
            mount_path = "/certs"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = "8443"
              scheme = "HTTPS"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          image_pull_policy = "Always"

          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = var.k8s_name

        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }

    revision_history_limit = 10
  }
}

resource "kubernetes_service" "dashboard_metrics_scraper" {
  metadata {
    name      = var.scraper_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.scraper_name
    }
  }

  spec {
    port {
      port        = 8000
      target_port = "8000"
    }

    selector = {
      k8s-app = var.scraper_name
    }
  }
}

resource "kubernetes_deployment" "dashboard_metrics_scraper" {
  metadata {
    name      = var.scraper_name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata.0.name

    labels = {
      k8s-app = var.scraper_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = var.scraper_name
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = var.scraper_name
        }

        annotations = {
          "seccomp.security.alpha.kubernetes.io/pod" = "runtime/default"
        }
      }

      spec {
        volume {
          name = "tmp-volume"
        }

        container {
          name  = var.scraper_name
          image = "kubernetesui/metrics-scraper:${var.scraper_tag}"

          port {
            container_port = 8000
            protocol       = "TCP"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = "8000"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = var.k8s_name

        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }

    revision_history_limit = 10
  }
}

