# packer build -force .

locals {
  access_key = vault("/kv-v2/data/alicloud", "access_key")
  secret_key = vault("/kv-v2/data/alicloud", "secret_key")
}

variable "region" {
  default     = "ap-southeast-1"
  description = "https://www.alibabacloud.com/help/doc-detail/40654.htm"
}

source "alicloud-ecs" "basic-example" {
  access_key           = local.access_key
  secret_key           = local.secret_key
  region               = var.region
  image_name           = "ssh_otp_image_1_1"
  source_image         = "centos_7_9_x64_20G_alibase_20210623.vhd"
  ssh_username         = "root"
  instance_type        = "ecs.n1.tiny"
  io_optimized         = true
  internet_charge_type = "PayByTraffic"
  image_force_delete   = true
}

build {
  sources = ["sources.alicloud-ecs.basic-example"]

  provisioner "file" {
    source      = "./files/"
    destination = "/tmp"
  }

  provisioner "shell" {
    inline = [
      "cp /tmp/sshd /etc/pam.d/sshd",
      "cp /tmp/sshd_config /etc/ssh/sshd_config",
      "mkdir -p /etc/vault.d",
      "cp /tmp/vault.hcl /etc/vault.d/vault.hcl",
      "cp /tmp/vault-ssh-helper /usr/bin/vault-ssh-helper",
      "/usr/bin/vault-ssh-helper -verify-only -config=/etc/vault.d/vault.hcl -dev",
      "sudo adduser test",
      "echo password | passwd --stdin test",
      "echo 'test ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
      "sudo sed -ie 's/SELINUX=enforcing/SELINUX=disabled /g' /etc/selinux/config"
    ]
  }
}