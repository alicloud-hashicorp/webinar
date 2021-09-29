data "alicloud_images" "packer" {
  most_recent = true
  name_regex  = "^ssh_otp_image*"
}

data "alicloud_instance_types" "default" {
  cpu_core_count       = 2
  memory_size          = 4
  kubernetes_node_role = "Worker"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "alicloud_cs_managed_kubernetes" "default" {
  name                         = var.name
  cluster_spec                 = "ack.pro.small"
  is_enterprise_security_group = true
  worker_number                = 0
  // password                     = "Hello1234"
  password = random_password.password.result

  // Custom Image support. Must based on CentOS7 or AliyunLinux2.
  image_id              = data.alicloud_images.packer.ids.0
  pod_cidr              = "172.20.0.0/16"
  service_cidr          = "172.21.0.0/20"
  worker_vswitch_ids    = [alicloud_vswitch.vswitch.id]
  worker_instance_types = [data.alicloud_instance_types.default.instance_types.0.id]
}

resource "alicloud_cs_kubernetes_node_pool" "default" {
  name        = var.name
  cluster_id  = alicloud_cs_managed_kubernetes.default.id
  vswitch_ids = [alicloud_vswitch.vswitch.id]
  // image_id       = data.alicloud_images.packer.ids.0
  instance_types = [data.alicloud_instance_types.default.instance_types.0.id]

  system_disk_category = "cloud_efficiency"
  system_disk_size     = 40
  password             = random_password.password.result

  install_cloud_monitor = true
  node_count            = 2
}