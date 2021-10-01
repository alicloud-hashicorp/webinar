server = false
client_addr = "0.0.0.0"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o="
// https://www.nomadproject.io/docs/configuration/server_join#cloud-auto-join
// https://github.com/hashicorp/go-discover/tree/master/provider/aliyun
retry_join = ["provider=aliyun region=ap-southeast-1 tag_key=type tag_value=consul-nomad-server access_key_id=XXXXXXXXXX access_key_secret=XXXXXXXXXXXXXX"]
data_dir = "/consul/data"
acl {
  enabled = false
}
ports {
  grpc = 8502
}
connect {
  enabled = true
}