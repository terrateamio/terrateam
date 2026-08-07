resource "signalfx_single_value_chart" "k8s_available_pods_by_deployments" {
  name        = "# Available pods by deployments"
  description = "Number of pods ready by deployments"

  program_text = "A = data('k8s.deployment.available', rollup='latest').sum(by=['k8s.cluster.name', 'k8s.namespace.name', 'k8s.deployment.name']).sum().publish(label='A')"

  color_by         = "Dimension"
  refresh_interval = 5

  viz_options {
    display_name = "Available pods"
    label        = "A"
  }
}

resource "signalfx_list_chart" "k8s_top_10_cpu_usage_per_pod" {
  name        = "Top 10 CPU usage per pod (CPU units)"
  description = "Pod name | Node name"

  program_text = <<-EOF
A = data('container_cpu_utilization', rollup='rate').mean(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).scale(0.01).top(count=10).publish(label='A')
B = data('container.cpu.time').mean(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).top(count=10).publish(label='B')
EOF

  sort_by = "-value"

  disable_sampling    = true
  hide_missing_values = true
  max_precision       = 5
  refresh_interval    = 5
  time_range          = 900

  legend_options_fields {
    enabled  = false
    property = "sf_metric"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.pod.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.node.name"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_originatingMetric"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.cluster.name"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.pod.uid"
  }

  viz_options {
    display_name = "OTel pre translated CPU usage"
    label        = "B"
  }
  viz_options {
    display_name = "Top 10 pods by average CPU usage"
    label        = "A"
  }
}

resource "signalfx_time_chart" "k8s_network_bytes_per_sec" {
  name        = "Network bytes / sec"
  description = ""

  program_text = "A = data('k8s.pod.network.io', filter=filter('k8s.cluster.name', '*') and filter('k8s.namespace.name', '*') and filter('sf_tags', '*', match_missing=True) and filter('k8s.deployment.name', '*', match_missing=True), rollup='rate', extrapolation='zero').sum(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).publish(label='A')"

  plot_type = "ColumnChart"

  time_range  = 900
  unit_prefix = "Binary"

  axes_precision = 0

  disable_sampling = true
  axis_left {
    high_watermark = 179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    label          = "Rx bytes /sec (RED)"
    low_watermark  = -179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    max_value      = 179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    min_value      = 0
  }

  axis_right {
    high_watermark = 179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    label          = "Tx bytes /sec (BLUE)"
    low_watermark  = -179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    max_value      = 179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    min_value      = 0
  }

  histogram_options {
    color_theme = "gold"
  }

  viz_options {
    axis         = "left"
    color        = "brown"
    display_name = "Network bytes / sec"
    label        = "A"
    value_unit   = "Byte"
  }
}

resource "signalfx_single_value_chart" "k8s_desired_pods_by_deployments" {
  name        = "# Desired pods by deployments"
  description = "Number of pods that should be created by deployments"

  program_text = "A = data('k8s.deployment.desired', rollup='latest').sum(by=['k8s.cluster.name', 'k8s.namespace.name', 'k8s.deployment.name']).sum().publish(label='A')"

  color_by         = "Dimension"
  refresh_interval = 5

  viz_options {
    display_name = "Desired pods by deployments"
    label        = "A"
  }
}

resource "signalfx_list_chart" "k8s_network_errors_per_sec" {
  name        = "Network errors / sec"
  description = ""

  program_text = "A = data('k8s.pod.network.errors', filter=filter('k8s.cluster.name', '*') and filter('k8s.namespace.name', '*') and filter('k8s.deployment.name', '*', match_missing=True) and filter('sf_tags', '*', match_missing=True), rollup='rate').sum(by=['k8s.pod.name', 'k8s.cluster.name', 'k8s.node.name', 'k8s.pod.uid']).publish(label='A')"

  sort_by = "-value"

  disable_sampling = true
  max_precision    = 4
  refresh_interval = 5
  time_range       = 900

  legend_options_fields {
    enabled  = true
    property = "k8s.pod.name"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_originatingMetric"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_metric"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.node.name"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.cluster.name"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.pod.uid"
  }

  viz_options {
    color        = "brown"
    display_name = "Network error / sec"
    label        = "A"
  }
}

resource "signalfx_time_chart" "k8s_memory_usage_pct" {
  name        = "Memory usage (%)"
  description = "With EKS/Fargate metric data can possibly go >100%"

  program_text = <<-EOF
A = data('container.memory.usage', filter=filter('k8s.cluster.name', '*') and filter('k8s.namespace.name', '*') and filter('k8s.deployment.name', '*', match_missing=True) and filter('sf_tags', '*', match_missing=True)).sum(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).publish(label='A', enable=False)
B = data('k8s.container.memory_limit', filter=filter('k8s.cluster.name', '*') and filter('k8s.namespace.name', '*') and filter('k8s.deployment.name', '*', match_missing=True) and filter('sf_tags', '*', match_missing=True)).sum(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).above(0, inclusive=True).publish(label='B', enable=False)
C = (A/B*100).publish(label='C')
EOF

  plot_type = "LineChart"


  time_range        = 900
  disable_sampling  = true
  axes_precision    = 0
  axes_include_zero = true


  axis_left {
    high_watermark = 179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    label          = "% memory used"
    low_watermark  = -179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    max_value      = 110
    min_value      = -179769313486231570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
  }

  histogram_options {
    color_theme = "gold"
  }

  legend_options_fields {
    enabled  = true
    property = "k8s.pod.name"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_metric"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.node.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.cluster.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.pod.uid"
  }

  viz_options {
    axis         = "left"
    display_name = "Memory used (%)"
    label        = "C"
    value_suffix = "%"
  }
  viz_options {
    axis         = "left"
    color        = "blue"
    display_name = "Container"
    label        = "A"
  }
  viz_options {
    axis         = "left"
    color        = "yellow"
    display_name = "Limit"
    label        = "B"
  }
}

resource "signalfx_single_value_chart" "k8s_active_pods" {
  name        = "# Active pods"
  description = "This may include \"pause\" containers used internally by k8s"

  program_text = "A = data('k8s.pod.phase').between(1.5, 2.5, low_inclusive=True, high_inclusive=True).count().publish(label='A')"

  color_by         = "Dimension"
  refresh_interval = 5

  viz_options {
    display_name = "Number of pods"
    label        = "A"
  }
}

resource "signalfx_list_chart" "k8s_top_10_pods_by_avg_memory_usage" {
  name        = "Top 10 pods by average memory usage (bytes)"
  description = "Pod name | Node name"

  program_text = "A = data('container.memory.usage', filter=filter('k8s.cluster.name', '*') and filter('k8s.namespace.name', '*') and filter('k8s.deployment.name', '*', match_missing=True) and filter('sf_tags', '*', match_missing=True)).mean(by=['k8s.pod.name', 'k8s.node.name', 'k8s.cluster.name', 'k8s.pod.uid']).top(count=10).publish(label='A')"

  sort_by = "-value"

  disable_sampling        = true
  unit_prefix             = "Binary"
  refresh_interval        = 5
  max_precision           = 4
  secondary_visualization = "None"
  time_range              = 900

  legend_options_fields {
    enabled  = true
    property = "k8s.pod.name"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_originatingMetric"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_metric"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.node.name"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.cluster.name"
  }
  legend_options_fields {
    enabled  = false
    property = "k8s.pod.uid"
  }

  viz_options {
    display_name = "Top 10 pods by average memory usage"
    label        = "A"
    value_unit   = "Byte"
  }
}

resource "signalfx_list_chart" "k8s_pods_by_phase" {
  name        = "# Pods by phase"
  description = ""

  program_text = <<-EOF
B = data('k8s.pod.phase', rollup='latest').between(1.5, 2.5, low_inclusive=True, high_inclusive=True).count().publish(label='B')
A = data('k8s.pod.phase', rollup='latest').between(0, 1.5, low_inclusive=True, high_inclusive=True).count().publish(label='A')
C = data('k8s.pod.phase', rollup='latest').between(2.5, 3.5, low_inclusive=True, high_inclusive=True).count().publish(label='C')
D = data('k8s.pod.phase', rollup='latest').between(3.5, 4.5, low_inclusive=True, high_inclusive=True).count().publish(label='D')
E = data('k8s.pod.phase', rollup='latest').between(4.5, 5.5, low_inclusive=True, high_inclusive=True).count().publish(label='E')
EOF

  sort_by = "+sf_originatingMetric"

  disable_sampling = true
  max_precision    = 4
  refresh_interval = 5
  time_range       = 900

  legend_options_fields {
    enabled  = false
    property = "sf_originatingMetric"
  }
  legend_options_fields {
    enabled  = true
    property = "sf_metric"
  }

  viz_options {
    color        = "azure"
    display_name = "Succeeded"
    label        = "C"
    value_suffix = "pods"
  }
  viz_options {
    color        = "brown"
    display_name = "Failed"
    label        = "D"
    value_suffix = "pods"
  }
  viz_options {
    color        = "purple"
    display_name = "Unknown"
    label        = "E"
    value_suffix = "pods"
  }
  viz_options {
    color        = "yellow"
    display_name = "Pending"
    label        = "A"
    value_suffix = "pods"
  }
  viz_options {
    color        = "yellowgreen"
    display_name = "Running"
    label        = "B"
    value_suffix = "pods"
  }
}

resource "signalfx_time_chart" "k8s_memory_usage_bytes" {
  name        = "Memory usage (bytes)"
  description = ""

  program_text = "A = data('container.memory.usage', filter=filter('k8s.node.name', '*')).sum(by=['k8s.cluster.name', 'k8s.namespace.name', 'k8s.pod.uid', 'k8s.pod.name', 'k8s.node.name']).publish(label='A')"

  plot_type = "LineChart"


  axes_precision   = 0
  disable_sampling = true
  time_range       = 900
  unit_prefix      = "Binary"

  histogram_options {
    color_theme = "gold"
  }

  legend_options_fields {
    enabled  = true
    property = "kubernetes_pod_name"
  }
  legend_options_fields {
    enabled  = true
    property = "kubernetes_namespace"
  }
  legend_options_fields {
    enabled  = true
    property = "kubernetes_cluster"
  }
  legend_options_fields {
    enabled  = true
    property = "kubernetes_pod_uid"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_originatingMetric"
  }
  legend_options_fields {
    enabled  = false
    property = "sf_metric"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.namespace.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.pod.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.cluster.name"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.pod.uid"
  }
  legend_options_fields {
    enabled  = true
    property = "k8s.node.name"
  }

  viz_options {
    axis         = "left"
    display_name = "Memory usage per pod"
    label        = "A"
    value_unit   = "Byte"
  }
}


resource "signalfx_dashboard" "runner_k8s" {
  name            = "K8S Runners"
  description     = "Kubernetes-based runners: pod states, CPU, memory, and network health."
  dashboard_group = var.dashboard_group

  variable {
    property               = "k8s.namespace.name"
    alias                  = "ForgeCICD Tenant Name"
    description            = ""
    values                 = []
    value_required         = false
    values_suggested       = var.tenant_names
    restricted_suggestions = true
  }

  variable {
    property               = "k8s.pod.name"
    alias                  = "ForgeCICD Instance Id"
    description            = ""
    values                 = []
    value_required         = false
    values_suggested       = []
    restricted_suggestions = false
  }

  dynamic "variable" {
    for_each = var.dynamic_variables
    iterator = var_def

    content {
      property               = var_def.value.property
      alias                  = var_def.value.alias
      description            = var_def.value.description
      values                 = var_def.value.values
      value_required         = var_def.value.value_required
      values_suggested       = var_def.value.values_suggested
      restricted_suggestions = var_def.value.restricted_suggestions
    }
  }
  chart {
    chart_id = signalfx_single_value_chart.k8s_active_pods.id
    row      = 0
    column   = 0
    width    = 3
    height   = 1
  }

  chart {
    chart_id = signalfx_single_value_chart.k8s_available_pods_by_deployments.id
    row      = 0
    column   = 3
    width    = 3
    height   = 1
  }

  chart {
    chart_id = signalfx_list_chart.k8s_top_10_pods_by_avg_memory_usage.id
    row      = 0
    column   = 9
    width    = 3
    height   = 2
  }

  chart {
    chart_id = signalfx_single_value_chart.k8s_desired_pods_by_deployments.id
    row      = 0
    column   = 6
    width    = 3
    height   = 1
  }

  chart {
    chart_id = signalfx_list_chart.k8s_pods_by_phase.id
    row      = 1
    column   = 0
    width    = 3
    height   = 2
  }

  chart {
    chart_id = signalfx_time_chart.k8s_memory_usage_pct.id
    row      = 1
    column   = 3
    width    = 3
    height   = 1
  }

  chart {
    chart_id = signalfx_time_chart.k8s_memory_usage_bytes.id
    row      = 1
    column   = 6
    width    = 3
    height   = 1
  }

  chart {
    chart_id = signalfx_list_chart.k8s_network_errors_per_sec.id
    row      = 2
    column   = 3
    width    = 5
    height   = 1
  }

  chart {
    chart_id = signalfx_time_chart.k8s_network_bytes_per_sec.id
    row      = 2
    column   = 8
    width    = 4
    height   = 1
  }

  chart {
    chart_id = signalfx_list_chart.k8s_top_10_cpu_usage_per_pod.id
    row      = 3
    column   = 0
    width    = 3
    height   = 2
  }
}
