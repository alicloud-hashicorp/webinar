data "alicloud_vswitches" "default" {
  name_regex = "^${var.name}"
}

resource "alicloud_security_group" "group" {
  name   = var.name
  vpc_id = data.alicloud_vswitches.default.vswitches.0.vpc_id
}

resource "alicloud_security_group_rule" "ssh" {
  type        = "ingress"
  ip_protocol = "tcp"
  // nic_type          = "internet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "vault" {
  type        = "ingress"
  ip_protocol = "tcp"
  // nic_type          = "internet"
  policy            = "accept"
  port_range        = "8200/8200"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

data "alicloud_instance_types" "c2g4" {
  cpu_core_count = 2
  memory_size    = 4
}

// https://partners-intl.aliyun.com/help/doc-detail/108393.htm
data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_18.*64"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "alicloud_kms_key" "key" {
  description             = "Vault KMS"
  pending_window_in_days  = "7"
  status                  = "Enabled"
}

resource "alicloud_instance" "vault" {
  depends_on = [alicloud_kms_key.key]
  security_groups = alicloud_security_group.group.*.id

  # series III
  instance_type              = data.alicloud_instance_types.c2g4.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-vault"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.ubuntu.ids.0
  instance_name              = "vault"
  vswitch_id                 = data.alicloud_vswitches.default.ids.0
  internet_max_bandwidth_out = 10
  user_data                  = local.user_data
  password                   = random_password.password.result
  //   data_disks {
  //     name        = "disk2"
  //     size        = 20
  //     category    = "cloud_efficiency"
  //     description = "disk2"
  //     encrypted   = true
  //     kms_key_id  = alicloud_kms_key.key.id
  //   }
}

locals {
  user_data = <<EOF
#!/bin/bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install software-properties-common -y
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault  -y
sudo systemctl enable vault

sudo mkdir -p /vault/{data, plugins}
sudo chown -R vault:vault /vault

sudo cat <<EOCONFIG > /etc/vault.d/vault.hcl
ui = true

storage "file" {
  path    = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
disable_mlock = true
default_lease_ttl = "768h"
max_lease_ttl = "768h"
api_addr = "http://127.0.0.1:8200"

plugin_directory = "/vault/plugins"

seal "alicloudkms" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  kms_key_id = "${alicloud_kms_key.key.id}"
}
EOCONFIG

sudo systemctl start vault
VAULT_ADDR=http://127.0.0.1:8200 vault operator init > /vault/key.txt
EOF
}

// s.73gzWIZMN1wfz2TlRxepCQyo