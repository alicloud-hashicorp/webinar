output "lb_address_dev" {
  description = "alicloud_slb_load_balancer address"
  value       = alicloud_slb_load_balancer.dev.address
}

output "dns_address_dev" {
  value = "http://${alicloud_dns_record.dev.host_record}.${alicloud_dns_record.dev.name}"
}

output "lb_address_prod" {
  description = "alicloud_slb_load_balancer address"
  value       = alicloud_slb_load_balancer.prod.address
}

output "dns_address_prod" {
  value = "http://${alicloud_dns_record.prod.host_record}.${alicloud_dns_record.prod.name}"
}