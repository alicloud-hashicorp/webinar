variable "region" {
  default     = "ap-southeast-1"
  description = "https://www.alibabacloud.com/help/doc-detail/40654.htm"
}

variable "name" {
  default = "episode-02"
}

variable "vm_count_dev" {
  default = 0
}

variable "vm_count_prod" {
  default = 0
}

variable "access_key" {}
variable "secret_key" {}