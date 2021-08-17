// https://www.alibabacloud.com/ko/solutions/devops/terraform
// https://registry.terraform.io/providers/aliyun/alicloud/latest/docs

terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = ">= 1.131"
    }
  }
}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "alicloud_instance_types" "c2g4" {
  cpu_core_count = 2
  memory_size    = 4
}

// https://partners-intl.aliyun.com/help/doc-detail/108393.htm
data "alicloud_images" "default" {
  name_regex  = "^centos"
  most_recent = true
  owners      = "system"
}