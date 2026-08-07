output "nginxinc_ingress_controller" {
  value = {
    ingress_class_name = (
      var.nginxinc_ingress_controller.enabled
      ? var.nginxinc_ingress_controller.ingress_class_name
      : null
    )
    load_balancer_host = try(
      data.kubernetes_service_v1.nginxinc_ingress_controller[0]
      .status[0]
      .load_balancer[0]
      .ingress[0]
      .hostname,
      null
    )
  }
}
