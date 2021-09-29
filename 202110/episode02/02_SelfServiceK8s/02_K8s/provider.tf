// https://www.alibabacloud.com/ko/solutions/devops/terraform
// https://registry.terraform.io/providers/aliyun/alicloud/latest/docs
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "great-stone-biz"

    workspaces {
      name = "alibaba-session2-02-k8s"
    }
  }
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "> 2.4"
    }
  }
}

data "terraform_remote_state" "ack" {
  backend = "remote"

  config = {
    organization = "great-stone-biz"
    workspaces = {
      name = "alibaba-session2-01-ack"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.ack.outputs.ack_connections.api_server_internet
  client_certificate     = base64decode(data.terraform_remote_state.ack.outputs.kubecert.client_cert)
  client_key             = base64decode(data.terraform_remote_state.ack.outputs.kubecert.client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.ack.outputs.kubecert.cluster_cert)
}