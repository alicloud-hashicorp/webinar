data "kubernetes_all_namespaces" "allns" {}

output "all-ns" {
  value = data.kubernetes_all_namespaces.allns.namespaces
}

output "dashboard_lb" {
  value = "https://${kubernetes_service.kubernetes_dashboard.status.0.load_balancer.0.ingress.0.ip}"
}

output "token" {
  value = nonsensitive(data.kubernetes_secret.admin.data.token)
}