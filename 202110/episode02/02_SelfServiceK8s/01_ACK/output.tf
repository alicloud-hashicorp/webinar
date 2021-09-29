locals {
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.tpl", {
    endpoint   = alicloud_cs_managed_kubernetes.default.connections.api_server_internet
    user_id    = data.alicloud_account.current.id
    cluster_id = alicloud_cs_managed_kubernetes.default.id
    ca_data    = alicloud_cs_managed_kubernetes.default.certificate_authority.cluster_cert
    cert_data  = alicloud_cs_managed_kubernetes.default.certificate_authority.client_cert
    key_data   = alicloud_cs_managed_kubernetes.default.certificate_authority.client_key
  })
}

output "ack_connections" {
  value = alicloud_cs_managed_kubernetes.default.connections
}

output "kubeconfig" {
  description = "kubectl config file contents for this ACK cluster. Will block on cluster creation until the cluster is really ready."
  value       = local.kubeconfig
  depends_on  = [alicloud_cs_kubernetes_node_pool.default]
}

output "kubecert" {
  value     = alicloud_cs_managed_kubernetes.default.certificate_authority
  sensitive = true
}