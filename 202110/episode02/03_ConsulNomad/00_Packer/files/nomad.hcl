data_dir = "/nomad/data"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
// https://www.nomadproject.io/docs/configuration/server_join#cloud-auto-join
// https://github.com/hashicorp/go-discover/tree/master/provider/aliyun
server_join {
  retry_join = ["provider=aliyun region=ap-southeast-1 tag_key=type tag_value=consul-nomad-server access_key_id=XXXXXXXXX access_key_secret=XXXXXXXXXXXX"]
}
server {
  enabled          = false
}
client {
  enabled = true
  // servers = ["${alicloud_instance.server.private_ip}:4647"]
  meta {
    "subject" = "snapshot"
  }
  options = {
    "driver.raw_exec.enable" = "1"
  }
}