// https://www.alibabacloud.com/ko/solutions/devops/terraform
// https://registry.terraform.io/providers/aliyun/alicloud/latest/docs

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "great-stone-biz"

    workspaces {
      name = "alibaba-session2-01-ack"
    }
  }
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

data "alicloud_account" "current" {
}