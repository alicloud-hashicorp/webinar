output "public_ip" {
  description = "alicloud_instance server address"
  value       = alicloud_instance.server.public_ip
}

output "password" {
  value = nonsensitive(random_password.password.result)
}

output "ssh" {
  value = "sshpass -p${nonsensitive(random_password.password.result)} ssh root@${alicloud_instance.server.public_ip}"
}

output "dns_address_prod" {
  value = "http://${alicloud_dns_record.haproxy.host_record}.${alicloud_dns_record.haproxy.name}"
}