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
  length           = 16
  special          = false
}

resource "alicloud_instance" "vault" {
  security_groups   = alicloud_security_group.group.*.id

  # series III
  instance_type              = data.alicloud_instance_types.c2g4.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-vault"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.ubuntu.ids.0
  instance_name              = "vault"
  vswitch_id                 = alicloud_vswitch.vswitch.id
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
sudo systemctl start vault
EOF
}