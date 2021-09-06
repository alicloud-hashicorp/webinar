data "terraform_remote_state" "ecs" {
  backend = "remote"

  config = {
    organization = "great-stone-biz"
    workspaces = {
      name = "alibaba-session1-ecs"
    }
  }
}

resource "alicloud_slb_load_balancer" "default" {
  load_balancer_name = var.name
  vswitch_id         = data.terraform_remote_state.ecs.outputs.vswitchid
  address_type       = "internet"
  load_balancer_spec = "slb.s2.small"
  master_zone_id     = "ap-southeast-1c"
  slave_zone_id      = "ap-southeast-1b"
}

resource "alicloud_slb_backend_server" "default" {
  load_balancer_id = alicloud_slb_load_balancer.default.id

  dynamic "backend_servers" {
    for_each = data.terraform_remote_state.ecs.outputs.ecs_ids
    content {
      server_id = backend_servers.value
      weight    = 100
    }
  }
}

resource "alicloud_slb_listener" "default" {
  load_balancer_id          = alicloud_slb_load_balancer.default.id
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
//   acl_status      = "on"
//   acl_type        = "white"
//   acl_id          = alicloud_slb_acl.default.id
  request_timeout = 80
  idle_timeout    = 30
}

// resource "alicloud_slb_acl" "default" {
//   name       = var.name
//   ip_version = var.ip_version
//   entry_list {
//     entry    = "0.0.0.0/0"
//     comment  = "public"
//   }
//   entry_list {
//     entry   = "10.10.10.0/24"
//     comment = "first"
//   }
//   entry_list {
//     entry   = "168.10.10.0/24"
//     comment = "second"
//   }
// }