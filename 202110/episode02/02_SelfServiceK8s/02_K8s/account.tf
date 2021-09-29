// https://computingforgeeks.com/create-admin-user-to-access-kubernetes-dashboard/

variable "admin" {
  default = "my-admin"
}

resource "kubernetes_service_account" "admin" {
  metadata {
    name      = var.admin
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = var.admin
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.admin
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

data "kubernetes_secret" "admin" {
  metadata {
    name      = kubernetes_service_account.admin.default_secret_name
    namespace = "kube-system"
  }
}