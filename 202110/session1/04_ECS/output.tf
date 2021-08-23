output "public_ip" {
  description = "The private ip of the instance."
  value       = alicloud_instance.test.*.public_ip
}

output "ssh" {
  value = "ssh -o StrictHostKeyChecking=no test@${alicloud_instance.test.0.public_ip}"
}

output "vault-otp" {
  value = "vault write ssh-otp/creds/otp_key_role ip=${alicloud_instance.test.0.public_ip}"
}