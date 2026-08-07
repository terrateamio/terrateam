resource "brightbox_volume" "this" {
  count            = length(var.volumes)
  name             = lookup(var.volumes, "name")
  image            = lookup(var.volumes, "image")
  size             = lookup(var.volumes, "size")
  description      = lookup(var.volumes, "description")
  encrypted        = lookup(var.volumes, "encrypted")
  filesystem_label = lookup(var.volumes, "filesystem_label")
  filesystem_type  = lookup(var.volumes, "filesystem_type")
  serial           = lookup(var.volumes, "serial")
  server           = var.volumes.server
  source           = lookup(var.volumes, "source")
}

resource "brightbox_server_group" "this" {
  for_each    = length(var.server_group)
  name        = lookup(var.server_group, "name")
  description = lookup(var.server_group, "description")
}

resource "brightbox_server" "this" {
  count               = length(var.server)
  name                = lookup(var.server, "name")
  volume              = lookup(var.server, "volume")
  server_groups       = lookup(var.server, "server_groups")
  image               = lookup(var.server, "image")
  type                = lookup(var.server, "type")
  zone                = lookup(var.server, "zone")
  locked              = lookup(var.server, "locked")
  disk_encrypted      = lookup(var.server, "disk_encrypted")
  disk_size           = lookup(var.server, "disk_size")
  snapshots_retention = lookup(var.server, "snapshots_retention")
  snapshots_schedule  = lookup(var.server, "snapshots_schedule")
  user_data           = lookup(var.server, "user_data")
  user_data_base64    = lookup(var.server, "user_data_base64")
}

resource "brightbox_server_group_membership" "this" {
  count   = length(var.server_group_membership)
  group   = lookup(var.server_group_membership, "group")
  servers = lookup(var.server_group_membership, "servers")
}

resource "brightbox_load_balancer" "this" {
  count                   = length(var.load_balancer)
  name                    = lookup(var.load_balancer, "name")
  policy                  = lookup(var.load_balancer, "policy")
  https_redirect          = lookup(var.load_balancer, "https_redirect")
  ssl_minimum_version     = lookup(var.load_balancer, "ssl_minimum_version")
  locked                  = lookup(var.load_balancer, "locked")
  nodes                   = lookup(var.load_balancer, "nodes")
  domains                 = lookup(var.load_balancer, "domains")
  certificate_pem         = lookup(var.load_balancer, "certificate_pem")
  certificate_private_key = lookup(var.load_balancer, "certificate_private_key")

  dynamic "listener" {
    for_each = lookup(var.load_balancer, "listener")
    content {
      protocol       = listener.value.protocol
      in             = listener.value.in
      out            = listener.value.out
      timeout        = listener.value.timeout
      proxy_protocol = listener.value.proxy_protocol
    }
  }

  dynamic "healthcheck" {
    for_each = lookup(var.load_balancer, "healthcheck")
    content {
      type           = healthcheck.value.type
      port           = healthcheck.value.port
      request        = healthcheck.value.request
      interval       = healthcheck.value.interval
      timeout        = healthcheck.value.timeout
      threshold_down = healthcheck.value.threshold_down
      threshold_up   = healthcheck.value.threshold_up
    }
  }
}