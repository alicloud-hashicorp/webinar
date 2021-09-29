// dev lb
resource "alicloud_slb_load_balancer" "dev" {
  load_balancer_name = "${var.name}-lb-dev"
  vswitch_id         = data.alicloud_vswitches.default.ids.0
  address_type       = "internet"
  load_balancer_spec = "slb.s2.small"
  master_zone_id     = "ap-southeast-1c"
  slave_zone_id      = "ap-southeast-1b"
}

resource "alicloud_slb_backend_server" "dev" {
  depends_on = [alicloud_instance.dev]
  count = length(alicloud_instance.dev.*) > 0 ? 1 : 0
  load_balancer_id = alicloud_slb_load_balancer.dev.id

  dynamic "backend_servers" {
    for_each = alicloud_instance.dev.*.id
    content {
      server_id = backend_servers.value
      weight    = 100
    }
  }
}

resource "alicloud_slb_listener" "dev" {
  load_balancer_id          = alicloud_slb_load_balancer.dev.id
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "tcp"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  request_timeout = 80
  idle_timeout    = 30
}

// prod lb
resource "alicloud_slb_load_balancer" "prod" {
  load_balancer_name = "${var.name}-lb-prod"
  vswitch_id         = data.alicloud_vswitches.default.ids.0
  address_type       = "internet"
  load_balancer_spec = "slb.s2.small"
  master_zone_id     = "ap-southeast-1c"
  slave_zone_id      = "ap-southeast-1b"
}

resource "alicloud_slb_backend_server" "prod" {
  depends_on = [alicloud_instance.prod]
  count = length(alicloud_instance.prod.*) > 0 ? 1 : 0
  load_balancer_id = alicloud_slb_load_balancer.prod.id

  dynamic "backend_servers" {
    for_each = alicloud_instance.prod.*.id
    content {
      server_id = backend_servers.value
      weight    = 100
    }
  }
}

resource "alicloud_slb_listener" "prod" {
  load_balancer_id          = alicloud_slb_load_balancer.prod.id
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "tcp"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  request_timeout = 80
  idle_timeout    = 30
}

resource "alicloud_dns_record" "dev" {
  name        = "4zangnim.com"
  host_record = "ep2-dev"
  type        = "A"
  value       = alicloud_slb_load_balancer.dev.address
}

resource "alicloud_dns_record" "prod" {
  name        = "4zangnim.com"
  host_record = "ep2-prod"
  type        = "A"
  value       = alicloud_slb_load_balancer.prod.address
}