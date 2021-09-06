variable "region" {
  default     = "ap-southeast-1"
  description = "https://www.alibabacloud.com/help/doc-detail/40654.htm"
}

variable "name" {
  default = "hashicorp-ecs"
}

variable "ip_version" {
  default = "ipv4"
}

variable "instance_count" {
  default = 0
}