output "public_ip" {
  description = "The private ip of the instance."
  value       = alicloud_instance.vault.public_ip
}

output "password" {
  value = nonsensitive(random_password.password.result)
}

output "ssh" {
  value = "sshpass -p${nonsensitive(random_password.password.result)} ssh root@${alicloud_instance.vault.public_ip}"
}