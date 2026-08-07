resource "kubectl_manifest" "vmrule_cluster" {
  yaml_body = yamlencode({
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMRule"
    metadata = {
      name      = "vmrule-hpa"
      namespace = var.namespace
    }
    spec = {
      groups = [
        {
          interval = "15s"
          name     = "K8sHPAs"
          rules = [
            {
              expr   = "sum(kube_hpa_status_current_replicas / kube_hpa_spec_max_replicas) by (namespace,hpa,cluster_name) * 100"
              record = "hpa:util"
            },
            {
              alert = "HPAUtil"
              annotations = {
                description = "`{{ $labels.namespace }}/{{ $labels.hpa }}` hpa in `{{ $labels.cluster_name }}` is maxed out"
                summary     = "High k8s HPA util"
                value       = "{{ $value }}"
              }
              expr = "hpa:util > 85"
              for  = "15m"
              labels = {
                severity = "warning"
                team     = "ops"
              }
            },
          ]
        },
      ]
    }
  })
}
