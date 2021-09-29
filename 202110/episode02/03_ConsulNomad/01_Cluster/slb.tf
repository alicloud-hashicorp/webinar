// haproxy lb
resource "alicloud_slb_load_balancer" "haproxy" {
  load_balancer_name = "${var.name}-lb-haproxy"
  vswitch_id         = data.alicloud_vswitches.default.ids.0
  address_type       = "internet"
  load_balancer_spec = "slb.s2.small"
  master_zone_id     = "ap-southeast-1c"
  slave_zone_id      = "ap-southeast-1b"
}

resource "alicloud_slb_backend_server" "haproxy" {
  depends_on = [alicloud_instance.client]
  count = length(alicloud_instance.client.*) > 0 ? 1 : 0
  load_balancer_id = alicloud_slb_load_balancer.haproxy.id

  dynamic "backend_servers" {
    for_each = alicloud_instance.client.*.id
    content {
      server_id = backend_servers.value
      weight    = 100
    }
  }
}

resource "alicloud_slb_listener" "haproxy" {
  load_balancer_id          = alicloud_slb_load_balancer.haproxy.id
  backend_port              = 8080
  frontend_port             = 80
  protocol                  = "tcp"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  request_timeout = 5
  idle_timeout    = 2
}

resource "alicloud_slb_listener" "stats" {
  load_balancer_id          = alicloud_slb_load_balancer.haproxy.id
  backend_port              = 1936
  frontend_port             = 1936
  protocol                  = "tcp"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  request_timeout = 5
  idle_timeout    = 2
}

resource "alicloud_dns_record" "haproxy" {
  name        = "4zangnim.com"
  host_record = "ep2-haproxy"
  type        = "A"
  value       = alicloud_slb_load_balancer.haproxy.address
}