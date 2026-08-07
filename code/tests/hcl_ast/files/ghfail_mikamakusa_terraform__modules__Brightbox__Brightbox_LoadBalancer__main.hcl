resource "brightbox_load_balancer" "bbx_loadbalancer" {
  count = length(var.bbx_lb)
  name  = lookup(var.bbx_lb[count.index], "name")
  nodes = [
    element(var.nodes, lookup(var.bbx_lb[count.index], "nodes", null))
  ]
  certificate_pem         = file(join(".", [join("/", [path.cwd, "certificate", lookup(var.bbx_lb[count.index], "certificate_pem")], "pem")]))
  certificate_private_key = file(join(".", [join("/", [path.cwd, "certificate", lookup(var.bbx_lb[count.index], "certificate_private_key")]), ".key"]))
  sslv3                   = lookup(var.bbx_lb[count.index], "sslv3", null)
  buffer_size             = lookup(var.bbx_lb[count.index], "buffer_size", null)

  dynamic "healthcheck" {
    for_each = lookup(var.bbx_lb[count.index], "healthcheck")
    content {
      port           = lookup(healthcheck.value, "port")
      type           = lookup(healthcheck.value, "type")
      request        = lookup(healthcheck.value, "request", null)
      interval       = lookup(healthcheck.value, "interval", null)
      threshold_up   = lookup(healthcheck.value, "threshold_up", null)
      threshold_down = lookup(healthcheck.value, "threshold_down", null)
    }
  }

  dynamic "listener" {
    for_each = lookup(var.bbx_lb[count.index], "listener")
    content {
      in       = lookup(listener.value, "in")
      out      = lookup(listener.value, "out")
      protocol = lookup(listener.value, "protocol")
      timeout  = lookup(listener.value, "timeout")
    }
  }
}
