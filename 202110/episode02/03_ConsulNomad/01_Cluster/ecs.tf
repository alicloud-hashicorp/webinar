locals {
  ingress_port = toset(["22/22", "8500/8500", "4646/4646", "8080/8080", "1936/1936"])
}

data "alicloud_vswitches" "default" {
  name_regex = "^${var.name}"
}

resource "alicloud_security_group" "group" {
  name   = "${var.name}-consulnomad"
  vpc_id = data.alicloud_vswitches.default.vswitches.0.vpc_id
}

// resource "alicloud_security_group_rule" "default" {
//   for_each = local.ingress_port
//   type        = "ingress"
//   ip_protocol = "tcp"
//   // nic_type          = "internet"
//   policy            = "accept"
//   port_range        = each.key
//   priority          = 1
//   security_group_id = alicloud_security_group.group.id
//   cidr_ip           = "0.0.0.0/0"
// }

data "alicloud_instance_types" "c4g8" {
  cpu_core_count = 4
  memory_size    = 8
}

data "alicloud_images" "centos" {
  most_recent = true
  name_regex  = "^centos_7"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "alicloud_instance" "server" {
  security_groups = alicloud_security_group.group.*.id

  instance_type              = data.alicloud_instance_types.c4g8.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-server"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.centos.ids.0
  instance_name              = "${var.name}-server"
  vswitch_id                 = data.alicloud_vswitches.default.ids.0
  internet_max_bandwidth_out = 10
  password                   = random_password.password.result
  user_data                  = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum update -y && sudo yum install consul nomad -y
sudo systemctl enable consul nomad

sudo mkdir -p /{consul,nomad}/data

sudo cat <<EOCONFIG > /etc/consul.d/consul.hcl
server = true
ui_config {
  enabled = true
}
bootstrap_expect = 1
client_addr = "0.0.0.0"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o="
data_dir = "/consul/data"
acl {
  enabled = false
}
ports {
  grpc = 8502
}
connect {
  enabled = true
}
EOCONFIG

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
data_dir = "/nomad/data"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
server {
  enabled          = true
  bootstrap_expect = 1
  encrypt = "H6NAbsGpPXKJIww9ak32DAV/kKAm7vh9awq0fTtUou8="
}
EOCONFIG

sudo chown -R consul:consul /consul
sudo chown -R nomad:nomad /nomad
sudo systemctl start consul
sudo systemctl start nomad
EOF
}

resource "alicloud_instance" "client" {
  depends_on = [alicloud_instance.server]
  count = 1
  security_groups = alicloud_security_group.group.*.id

  instance_type              = data.alicloud_instance_types.c4g8.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-client-${count.index}"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.centos.ids.0
  instance_name              = "${var.name}-client-${count.index}"
  vswitch_id                 = data.alicloud_vswitches.default.ids.0
  internet_max_bandwidth_out = 10
  password                   = random_password.password.result
  user_data                  = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum update -y && sudo yum install consul nomad java-11-openjdk-devel.x86_64 docker -y
sudo systemctl enable consul nomad docker

sudo mkdir -p /{consul,nomad}/data

sudo cat <<EOCONFIG > /etc/consul.d/consul.hcl
server = false
client_addr = "0.0.0.0"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o="
retry_join = ["${alicloud_instance.server.private_ip}"]
data_dir = "/consul/data"
acl {
  enabled = false
}
ports {
  grpc = 8502
}
connect {
  enabled = true
}
EOCONFIG

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
data_dir = "/nomad/data"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
server_join {
  retry_join = ["${alicloud_instance.server.private_ip}:4647"]
}
server {
  enabled          = false
}
client {
  enabled = true
  // servers = ["${alicloud_instance.server.private_ip}:4647"]
  meta {
    "subject" = "snapshot"
  }
  options = {
    "driver.raw_exec.enable" = "1"
  }
}
EOCONFIG

sudo chown -R consul:consul /consul
sudo chown -R nomad:nomad /nomad
sudo systemctl start consul
sudo systemctl start docker
sudo systemctl start nomad
EOF
}
