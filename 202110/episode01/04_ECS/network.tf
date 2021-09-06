resource "alicloud_vpc" "vpc" {
  vpc_name   = var.name
  cidr_block = "172.38.0.0/16"
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = "172.38.0.0/24"
  zone_id      = data.alicloud_zones.default.zones[0].id
  vswitch_name = var.name
}

resource "alicloud_security_group" "group" {
  name   = var.name
  vpc_id = alicloud_vpc.vpc.id
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
  // cidr_ip           = "172.38.0.0/24"
}