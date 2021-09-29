// https://www.alibabacloud.com/ko/solutions/devops/terraform
// https://registry.terraform.io/providers/aliyun/alicloud/latest/docs

terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.131"
    }
  }
}

provider "alicloud" {
  profile    = "gslee"
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "alicloud_vpc" "vpc" {
  vpc_name   = var.name
  cidr_block = "172.28.0.0/16"
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = "172.28.0.0/24"
  zone_id      = data.alicloud_zones.default.zones[0].id
  vswitch_name = var.name
}