data "alicloud_vswitches" "default" {
  name_regex = "^${var.name}"
}

resource "alicloud_security_group" "group" {
  name   = "${var.name}-immutable"
  vpc_id = data.alicloud_vswitches.default.vswitches.0.vpc_id
}

// resource "alicloud_security_group_rule" "ssh" {
//   type        = "ingress"
//   ip_protocol = "tcp"
//   // nic_type          = "internet"
//   policy            = "accept"
//   port_range        = "22/22"
//   priority          = 1
//   security_group_id = alicloud_security_group.group.id
//   cidr_ip           = "0.0.0.0/0"
// }

// resource "alicloud_security_group_rule" "vault" {
//   type        = "ingress"
//   ip_protocol = "tcp"
//   // nic_type          = "internet"
//   policy            = "accept"
//   port_range        = "80/80"
//   priority          = 1
//   security_group_id = alicloud_security_group.group.id
//   cidr_ip           = "0.0.0.0/0"
// }

data "alicloud_instance_types" "c1g2" {
  cpu_core_count = 1
  memory_size    = 2
}

data "alicloud_images" "dev" {
  most_recent = true
  name_regex  = "^episode02-dev*"
}

data "alicloud_images" "prod" {
  most_recent = true
  name_regex  = "^episode02-prod*"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "alicloud_instance" "dev" {
  count = var.vm_count_dev
  security_groups = alicloud_security_group.group.*.id

  # series III
  instance_type              = data.alicloud_instance_types.c1g2.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-dev-${count.index}"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.dev.ids.0
  instance_name              = "${var.name}-dev-${count.index}"
  vswitch_id                 = data.alicloud_vswitches.default.ids.0
  internet_max_bandwidth_out = 10
  password                   = random_password.password.result
}

resource "alicloud_instance" "prod" {
  count = var.vm_count_prod
  security_groups = alicloud_security_group.group.*.id

  # series III
  instance_type              = data.alicloud_instance_types.c1g2.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-prod-${count.index}"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.prod.ids.0
  instance_name              = "${var.name}-prod-${count.index}"
  vswitch_id                 = data.alicloud_vswitches.default.ids.0
  internet_max_bandwidth_out = 10
  password                   = random_password.password.result
}

//  export TF_VAR_parallelism=4