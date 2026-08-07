resource "humanitec_resource_definition" "servicemonitor-workload" {
  driver_type = "humanitec/template"
  id          = "servicemonitor-workload"
  name        = "servicemonitor-workload"
  type        = "workload"
  driver_inputs = {
    values_string = jsonencode({
      "namespace" = "$${resources['k8s-namespace#k8s-namespace'].outputs.namespace}"
      "templates" = {
        "init"      = <<END_OF_TEXT
workload: {{ .resource.id }}
{{- if gt (.resource.spec | dig "service" "ports" (list) | len) 0 }}
servicePort: {{ get (.resource.spec.service.ports | values | first ) "service_port" }}
{{- else }}
servicePort: 8080
{{- end }}
END_OF_TEXT
        "manifests" = <<END_OF_TEXT
{{- if .resource.spec.service }}
service-monitor.yaml:
  location: namespace
  data:
    apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: {{ .init.workload }}-svc-monitor
    spec:
      endpoints:
      - interval: 30s
        targetPort: {{ .init.servicePort }}
        path: /metrics
      namespaceSelector:
        matchNames:
        - {{ .driver.values.namespace }}
      selector:
        matchLabels:
          humanitec.io/workload: {{ .init.workload }}
{{- end }}
END_OF_TEXT
      }
    })
  }
}

