# https://github.com/hashicorp/go-discover/blob/master/provider/aliyun/aliyun_discover.go#L15-L28

# packer build -force .
variable "env" {
  default     = "consul-nomad"
}

locals {
  access_key = vault("/kv-alicloud/data/key", "access_key")
  secret_key = vault("/kv-alicloud/data/key", "secret_key")
  timestamp = formatdate("YYYYMMDD-hhmmss", timeadd(timestamp(), "9h"))
}

variable "region" {
  default     = "ap-southeast-1"
  description = "https://www.alibabacloud.com/help/doc-detail/40654.htm"
}

source "alicloud-ecs" "basic-example" {
  access_key           = local.access_key
  secret_key           = local.secret_key
  region               = var.region
  image_name           = "episode02-${var.env}-${local.timestamp}"
  source_image         = "centos_7_9_x64_20G_alibase_20210824.vhd"
  ssh_username         = "root"
  instance_type        = "ecs.n1.medium"
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

# Vault OTP
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

# Consul Nomad
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y yum-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
      "sudo yum update -y && sudo yum install consul nomad java-11-openjdk-devel.x86_64 docker -y",
      "sudo systemctl enable consul nomad docker",
      "sudo mkdir -p /{consul,nomad}/data",
      "cp /tmp/consul.hcl /etc/consul.d/consul.hcl",
      "cp /tmp/nomad.hcl /etc/nomad.d/nomad.hcl",
      "sudo chown -R consul:consul /consul",
      "sudo chown -R nomad:nomad /nomad",
    ]
  }
}