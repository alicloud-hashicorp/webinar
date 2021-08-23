data "alicloud_images" "packer" {
  most_recent = true
  name_regex  = "^ssh_otp_image*"
}

data "alicloud_instance_types" "normal" {
  cpu_core_count = 1
  memory_size    = 2
}

resource "alicloud_instance" "test" {
  count = 1
  security_groups   = alicloud_security_group.group.*.id

  # series III
  instance_type              = data.alicloud_instance_types.normal.ids.0
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "${var.name}-${count.index}"
  system_disk_size           = 50
  image_id                   = data.alicloud_images.packer.ids.0
  instance_name              = "${var.name}-${count.index}"
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = 10
}