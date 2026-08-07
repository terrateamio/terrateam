resource "kubectl_manifest" "vmrule_cluster" {
  yaml_body = yamlencode({
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMRule"
    metadata = {
      name      = "vmrule-cluster"
      namespace = var.namespace
    }
    spec = {
      groups = [
        {
          interval = "15s"
          name     = "K8sClusters"
          rules = [
            {
              expr   = "avg((avg (container_memory_working_set_bytes) by (container_name , pod ))/ on (container_name , pod)(avg (container_spec_memory_limit_bytes>0 ) by (container_name, pod))*100)"
              record = "cluster:mem_used"
            },           
            {
              expr   = "avg((sum (rate (container_cpu_usage_seconds_total{container_name!=\"\"} [5m])) by (namespace , cluster_name ) / on ( namespace, cluster_name) ((kube_pod_container_resource_limits_cpu_cores >0)*300))*100)"
              record = "cluster:cpu_used"
            },
            {
              alert = "HighClusterMem"
              annotations = {
                description = "`{{ $labels.cluster_name }}` cluster memory usage is high"
                summary     = "High k8s cluster Mem Usage"
                value       = "{{ $value }}"
              }
              expr = "cluster:mem_used > 90"
              for  = "1m"
              labels = {
                severity = "warning"
                team     = "ops"
              }
            },
            {
              alert = "HighClusterCPU"
              annotations = {
                description = "`{{ $labels.cluster_name }}` cluster cpu usage is high"
                summary     = "High k8s cluster CPU Usage"
                value       = "{{ $value }}"
              }
              expr = "cluster:cpu_used > 90"
              for  = "1m"
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
