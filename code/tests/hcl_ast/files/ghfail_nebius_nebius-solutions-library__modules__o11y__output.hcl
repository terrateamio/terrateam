output "nebius_application_status" {
  value = {
    loki       = var.o11y.loki.enabled ? nebius_applications_v1alpha1_k8s_release.loki[0].status : null
    prometheus = var.o11y.prometheus.enabled ? nebius_applications_v1alpha1_k8s_release.prometheus[0].status : null
  }
}

output "k8s_apps_status" {
  value = { for key, app in data.kubernetes_resource.o11y :
    key => app.kind == "Deployment" ?
    app.object.status.availableReplicas / app.object.status.replicas :
    app.object.status.numberAvailable / app.object.status.desiredNumberScheduled
  }
}

output "prometheus_grafana_password" {
  sensitive = true
  value     = var.o11y.prometheus.enabled ? random_password.grafana[0].result : null
}

output "nebius_grafana_password" {
  sensitive = true
  value     = var.o11y.grafana.enabled ? random_password.grafana_password[0].result : null
}

output "grafana_service_account" {
  description = "Grafana service account information"
  value = var.o11y.grafana.enabled && var.k8s_node_group_sa_enabled ? {
    id                = var.k8s_node_group_sa_id
    access_key_id     = nebius_iam_v2_access_key.grafana_key[0].status.aws_access_key_id
    secret_access_key = nebius_iam_v2_access_key.grafana_key[0].status.secret
    access_token      = local.grafana_access_token
  } : null
  sensitive = true
}