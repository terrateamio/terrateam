# signalfx_dashboard.APM_IMM-Exec:
resource "signalfx_dashboard" "APM_IMM-Exec" {
    charts_resolution = "default"
    dashboard_group   = signalfx_dashboard_group.exec_dashboard_group.id
    name              = "APM / IMM - Exec"
    time_range        = "-12w"

    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_2.id
        column   = 6
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_7.id
        column   = 9
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_0.id
        column   = 0
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_5.id
        column   = 3
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_3.id
        column   = 9
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_4.id
        column   = 0
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_6.id
        column   = 6
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.APM_IMM-Exec_1.id
        column   = 3
        height   = 2
        row      = 0
        width    = 3
    }

    variable {
        alias                  = "Environment"
        apply_if_exist         = false
        description            = "APM Environment Name"
        property               = "sf_environment"
        replace_only           = true
        restricted_suggestions = false
        value_required         = true
        values                 = [
            "*",
        ]
        values_suggested       = []
    }
    variable {
        alias                  = "Service"
        apply_if_exist         = false
        description            = "APM Service Name"
        property               = "sf_service"
        replace_only           = true
        restricted_suggestions = false
        value_required         = true
        values                 = [
            "*",
        ]
        values_suggested       = []
    }
}


# signalfx_list_chart.APM_IMM-Exec_0:
resource "signalfx_list_chart" "APM_IMM-Exec_0" {
    color_by                = "Metric"
    description             = "Traffic Change Top and Bottom 5 (12 week comparison)"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Request rate 12 week comparison"
    program_text            = <<-EOF
        A = data('service.request.count', filter=filter('sf_environment', '*') and filter('sf_service', '*'), rollup='rate').sum(by=['sf_service']).mean(over='7d').publish(label='A', enable=False)
        B = data('service.request.count', filter=filter('sf_environment', '*') and filter('sf_service', '*'), rollup='rate').sum(by=['sf_service']).timeshift('12w').mean(over='7d').publish(label='B', enable=False)
        C = (((A-B)/B)*100).mean(by=['sf_service']).mean(over='7d').top(count=5).publish(label='C')
        D = (((A-B)/B)*100).mean(by=['sf_service']).mean(over='7d').bottom(count=5).publish(label='D')
    EOF
    refresh_interval        = 3600
    secondary_visualization = "None"
    sort_by                 = "-value"
    time_range              = 900
    unit_prefix             = "Metric"

    viz_options {
        color        = "brown"
        display_name = "% Change"
        label        = "D"
        value_suffix = "%"
    }
    viz_options {
        color        = "gray"
        display_name = "% Change"
        label        = "C"
        value_suffix = "%"
    }
    viz_options {
        color        = "lilac"
        display_name = "Requests"
        label        = "A"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "Requests(-4w)"
        label        = "B"
        value_suffix = "requests/m"
    }
}
# signalfx_list_chart.APM_IMM-Exec_1:
resource "signalfx_list_chart" "APM_IMM-Exec_1" {
    color_by                = "Scale"
    description             = "Requests compared"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Total Request (4 & 12 week comparisons)"
    program_text            = <<-EOF
        C = data('service.request.count', filter=(not filter('sf_dimensionalized', '*')) and filter('sf_environment', '*') and filter('sf_service', '*'), rollup='rate').sum(over='1d').sum().publish(label='C')
        D = data('service.request.count', filter=(not filter('sf_dimensionalized', '*')) and filter('sf_environment', '*') and filter('sf_service', '*'), rollup='rate').sum(over='1d').sum().timeshift('4w').publish(label='D', enable=False)
        E = data('service.request.count', filter=(not filter('sf_dimensionalized', '*')) and filter('sf_environment', '*') and filter('sf_service', '*'), rollup='rate').sum(over='1d').sum().timeshift('12w').publish(label='E', enable=False)
        F = (((C-D)/C)*100).publish(label='F')
        G = (((C-E)/C)*100).publish(label='G')
    EOF
    secondary_visualization = "Radial"
    time_range              = 900
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = -100
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 100
    }

    viz_options {
        display_name = "% 12 week Change"
        label        = "G"
        value_suffix = "%"
    }
    viz_options {
        display_name = "% 4 week Change"
        label        = "F"
        value_suffix = "%"
    }
    viz_options {
        color        = "lilac"
        display_name = "-12w"
        label        = "E"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "-4w"
        label        = "D"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "Today"
        label        = "C"
        value_suffix = " "
    }
}
# signalfx_list_chart.APM_IMM-Exec_2:
resource "signalfx_list_chart" "APM_IMM-Exec_2" {
    color_by                = "Metric"
    description             = "Latency (P90) Top and Bottom 5 (12 week comparison)"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Latency (P90) 12 week comparison"
    program_text            = <<-EOF
        def weighted_duration(base, p, filter_, groupby):
            error_durations     = data(base + '.duration.ns.' + p, filter=filter_ and filter('sf_error', 'true'),  rollup='max').mean(by=groupby, allow_missing=['sf_httpMethod'])
            non_error_durations = data(base + '.duration.ns.' + p, filter=filter_ and filter('sf_error', 'false'), rollup='max').mean(by=groupby, allow_missing=['sf_httpMethod'])
        
            error_counts     = data(base + '.count', filter=filter_ and filter('sf_error', 'true'),  rollup='sum').sum(by=groupby, allow_missing=['sf_httpMethod'])
            non_error_counts = data(base + '.count', filter=filter_ and filter('sf_error', 'false'), rollup='sum').sum(by=groupby, allow_missing=['sf_httpMethod'])
        
            error_weight     = (error_durations * error_counts).sum(over='1m')
            non_error_weight = (non_error_durations * non_error_counts).sum(over='1m')
        
            total_weight = combine((error_weight if error_weight is not None else 0) + (non_error_weight if non_error_weight is not None else 0))
            total = combine((error_counts if error_counts is not None else 0) + (non_error_counts if non_error_counts is not None else 0)).sum(over='1m')
            return (total_weight / total)
        
        filter_ = filter('sf_environment', '*') and filter('sf_service', '*') and not filter('sf_dimensionalized', '*')
        groupby = ['sf_service', 'sf_environment']
        weighted_duration('service.request', 'p90', filter_, groupby).mean()
        
        A = weighted_duration('service.request', 'p90', filter_, groupby).mean(by=['sf_service']).mean(over='7d').publish(label='A', enable=False)
        B = weighted_duration('service.request', 'p90', filter_, groupby).mean(by=['sf_service']).timeshift('12w').mean(over='7d').publish(label='B', enable=False)
        C = (((A-B)/B)*100).mean(by=['sf_service']).mean(over='7d').top(count=5).publish(label='C')
        D = (((A-B)/B)*100).mean(by=['sf_service']).mean(over='7d').bottom(count=5).publish(label='D')
    EOF
    refresh_interval        = 3600
    secondary_visualization = "None"
    sort_by                 = "+value"
    time_range              = 900
    unit_prefix             = "Metric"

    viz_options {
        color        = "aquamarine"
        display_name = "% Change"
        label        = "D"
        value_suffix = "%"
    }
    viz_options {
        color        = "gray"
        display_name = "% Change"
        label        = "C"
        value_suffix = "%"
    }
    viz_options {
        color        = "lilac"
        display_name = "Requests"
        label        = "A"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "Requests(-4w)"
        label        = "B"
        value_suffix = "requests/m"
    }
}
# signalfx_list_chart.APM_IMM-Exec_3:
resource "signalfx_list_chart" "APM_IMM-Exec_3" {
    color_by                = "Scale"
    description             = "Latency (P90) Compared"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Latency (P90) (4 & 12 week comparisons)"
    program_text            = <<-EOF
        def weighted_duration(base, p, filter_, groupby):
            error_durations     = data(base + '.duration.ns.' + p, filter=filter_ and filter('sf_error', 'true'),  rollup='max').mean(by=groupby, allow_missing=['sf_httpMethod'])
            non_error_durations = data(base + '.duration.ns.' + p, filter=filter_ and filter('sf_error', 'false'), rollup='max').mean(by=groupby, allow_missing=['sf_httpMethod'])
        
            error_counts     = data(base + '.count', filter=filter_ and filter('sf_error', 'true'),  rollup='sum').sum(by=groupby, allow_missing=['sf_httpMethod'])
            non_error_counts = data(base + '.count', filter=filter_ and filter('sf_error', 'false'), rollup='sum').sum(by=groupby, allow_missing=['sf_httpMethod'])
        
            error_weight     = (error_durations * error_counts).sum(over='1m')
            non_error_weight = (non_error_durations * non_error_counts).sum(over='1m')
        
            total_weight = combine((error_weight if error_weight is not None else 0) + (non_error_weight if non_error_weight is not None else 0))
            total = combine((error_counts if error_counts is not None else 0) + (non_error_counts if non_error_counts is not None else 0)).sum(over='1m')
            return (total_weight / total)
        
        filter_ = filter('sf_environment', '*') and filter('sf_service', '*') and not filter('sf_dimensionalized', '*')
        groupby = ['sf_service', 'sf_environment']
        weighted_duration('service.request', 'p90', filter_, groupby)
        
        C = weighted_duration('service.request', 'p90', filter_, groupby).mean(over='1d').mean().scale(0.00000001).publish(label='C')
        D = weighted_duration('service.request', 'p90', filter_, groupby).mean(over='1d').mean().scale(0.00000001).timeshift('4w').publish(label='D', enable=False)
        E = weighted_duration('service.request', 'p90', filter_, groupby).mean(over='1d').mean().scale(0.00000001).timeshift('12w').publish(label='E', enable=False)
        F = (((C-D)/C)*100).publish(label='F')
        G = (((C-E)/C)*100).publish(label='G')
    EOF
    secondary_visualization = "Radial"
    time_range              = 900
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 340282346638528860000000000000000000000
        gte   = -100
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "red"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 100
    }

    viz_options {
        display_name = "% 12 week Change"
        label        = "G"
        value_suffix = "%"
    }
    viz_options {
        display_name = "% 4 week Change"
        label        = "F"
        value_suffix = "%"
    }
    viz_options {
        color        = "lilac"
        display_name = "-12w"
        label        = "E"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "-4w"
        label        = "D"
        value_suffix = "requests/m"
    }
    viz_options {
        color        = "lilac"
        display_name = "Today"
        label        = "C"
        value_unit   = "Millisecond"
    }
}
# signalfx_list_chart.APM_IMM-Exec_4:
resource "signalfx_list_chart" "APM_IMM-Exec_4" {
    color_by                = "Metric"
    description             = "Error rate Top and Bottom 5 (12 week comparison)"
    disable_sampling        = true
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Error rate 12 week comparison"
    program_text            = <<-EOF
        filter_ = filter('sf_environment', '*') and filter('sf_service', '*') and (not filter('sf_dimensionalized', '*'))
        A = data('service.request.count', filter=filter_ and filter('sf_error', 'true'), rollup='delta').sum(by=['sf_environment', 'sf_service']).mean(over='7d').publish(label='A', enable=False)
        B = data('service.request.count', filter=filter_, rollup='delta').sum(by=['sf_environment', 'sf_service']).mean(over='7d').publish(label='B', enable=False)
        C = combine(100*((A if A is not None else 0) / B)).publish(label='C', enable=False)
        D = combine(100*((A if A is not None else 0) / B)).timeshift('12w').publish(label='D', enable=False)
        
        E = (((C-D)/D)*100).mean(by=['sf_service']).mean(over='7d').top(count=5).publish(label='% Change')
        F = (((C-D)/D)*100).mean(by=['sf_service']).mean(over='7d').bottom(count=5).publish(label='% Change')
    EOF
    secondary_visualization = "None"
    sort_by                 = "+value"
    time_range              = 900
    unit_prefix             = "Metric"

    legend_options_fields {
        enabled  = false
        property = "sf_originatingMetric"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_service"
    }

    viz_options {
        display_name = "% Change"
        label        = "% Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "D"
        label        = "D"
    }
    viz_options {
        display_name = "Errors"
        label        = "A"
    }
    viz_options {
        display_name = "Requests"
        label        = "B"
    }
    viz_options {
        color        = "pink"
        display_name = "Error rate"
        label        = "C"
        value_suffix = "%"
    }
}
# signalfx_list_chart.APM_IMM-Exec_5:
resource "signalfx_list_chart" "APM_IMM-Exec_5" {
    color_by                = "Scale"
    description             = "Error rate compared"
    disable_sampling        = true
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 2
    name                    = "Error rate (4 & 12 week comparisons)"
    program_text            = <<-EOF
        filter_ = filter('sf_environment', '*') and filter('sf_service', '*') and (not filter('sf_dimensionalized', '*'))
        A = data('service.request.count', filter=filter_ and filter('sf_error', 'true'), rollup='delta').sum(by=['sf_environment', 'sf_service']).mean(over='1d').publish(label='A', enable=False)
        B = data('service.request.count', filter=filter_, rollup='delta').sum(by=['sf_environment', 'sf_service']).mean(over='1d').publish(label='B', enable=False)
        C = combine(100*((A if A is not None else 0) / B)).mean().publish(label='Today')
        D = combine(100*((A if A is not None else 0) / B)).mean().timeshift('4w').publish(label='4w', enable=False)
        E = combine(100*((A if A is not None else 0) / B)).mean().timeshift('12w').publish(label='12w', enable=False)
        
        F = (((C-D)/C)*100).publish(label='% 4 week Change')
        G = (((C-E)/C)*100).publish(label='% 12 week Change')
    EOF
    secondary_visualization = "Radial"
    sort_by                 = "-sf_metric"
    time_range              = 900
    unit_prefix             = "Metric"

    color_scale {
        color = "red"
        gt    = 2
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 10
    }
    color_scale {
        color = "green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 2
    }

    legend_options_fields {
        enabled  = false
        property = "sf_originatingMetric"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = false
        property = "sf_service"
    }
    legend_options_fields {
        enabled  = false
        property = "sf_environment"
    }

    viz_options {
        display_name = "% 12 week Change"
        label        = "% 12 week Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "% 4 week Change"
        label        = "% 4 week Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "12w"
        label        = "12w"
    }
    viz_options {
        display_name = "4w"
        label        = "4w"
    }
    viz_options {
        display_name = "Errors"
        label        = "A"
    }
    viz_options {
        display_name = "Requests"
        label        = "B"
    }
    viz_options {
        display_name = "Today"
        label        = "Today"
        value_suffix = "%"
    }
}
# signalfx_list_chart.APM_IMM-Exec_6:
resource "signalfx_list_chart" "APM_IMM-Exec_6" {
    color_by                = "Metric"
    description             = "Service Saturation of CPU/MEM/DISK Top and Bottom 5 (12 week comparison)"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 1
    name                    = "Host saturation 12 week comparison"
    program_text            = <<-EOF
        f = filter('sf_environment', '*') and filter('sf_service', '*')
        A = data('cpu.utilization', filter=f).mean(by='sf_service').publish(label='A', enable=False)
        B = data('memory.utilization', filter=f).mean(by='sf_service').publish(label='B', enable=False)
        C = data('disk.summary_utilization', filter=f).mean(by='sf_service').publish(label='C', enable=False)
        D = max(A, B, C).publish(label='Saturation', enable=False)
        E = max(A, B, C).timeshift('12w').publish(label='Saturation-12w', enable=False)
        
        G = (((E-D)/D)*100).mean(over='7d').top(count=5).publish(label='% Change')
        H = (((E-D)/D)*100).mean(over='7d').bottom(count=5).publish(label='% Change')
    EOF
    secondary_visualization = "None"
    sort_by                 = "+value"
    time_range              = 900
    unit_prefix             = "Metric"

    legend_options_fields {
        enabled  = false
        property = "cloud.account.id"
    }
    legend_options_fields {
        enabled  = false
        property = "cloud.availability_zone"
    }
    legend_options_fields {
        enabled  = true
        property = "cloud.platform"
    }
    legend_options_fields {
        enabled  = true
        property = "cloud.provider"
    }
    legend_options_fields {
        enabled  = false
        property = "gcp_id"
    }
    legend_options_fields {
        enabled  = true
        property = "host"
    }
    legend_options_fields {
        enabled  = false
        property = "host.id"
    }
    legend_options_fields {
        enabled  = false
        property = "host.name"
    }
    legend_options_fields {
        enabled  = false
        property = "host.type"
    }
    legend_options_fields {
        enabled  = false
        property = "k8s.cluster.name"
    }
    legend_options_fields {
        enabled  = false
        property = "k8s.node.name"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_cluster"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_node"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_node_uid"
    }
    legend_options_fields {
        enabled  = true
        property = "metric_source"
    }
    legend_options_fields {
        enabled  = true
        property = "os.type"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_service"
    }

    viz_options {
        display_name = "% Change"
        label        = "% Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "Saturation"
        label        = "Saturation"
    }
    viz_options {
        display_name = "Saturation-12w"
        label        = "Saturation-12w"
    }
    viz_options {
        display_name = "cpu.utilization"
        label        = "A"
        value_suffix = "%"
    }
    viz_options {
        display_name = "disk.summary_utilization"
        label        = "C"
        value_suffix = "%"
    }
    viz_options {
        display_name = "memory.utilization"
        label        = "B"
        value_suffix = "%"
    }
}
# signalfx_list_chart.APM_IMM-Exec_7:
resource "signalfx_list_chart" "APM_IMM-Exec_7" {
    color_by                = "Scale"
    description             = "Service Saturation of mean CPU/MEM/DISK compared"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 1
    name                    = "Host saturation (4 & 12 week comparisons)"
    program_text            = <<-EOF
        f = filter('sf_environment', '*') and filter('sf_service', '*')
        A = data('cpu.utilization', filter=f).mean(by='sf_service').publish(label='A', enable=False)
        B = data('memory.utilization', filter=f).mean(by='sf_service').publish(label='B', enable=False)
        C = data('disk.summary_utilization', filter=f).mean(by='sf_service').publish(label='C', enable=False)
        D = max(A, B, C).mean().publish(label='Today')
        E = max(A, B, C).mean().timeshift('4w').publish(label='% 4', enable=False)
        G = max(A, B, C).mean().timeshift('12w').publish(label='% 12', enable=False)
        H = (((D-E)/D)*100).publish(label='% 4 week Change')
        I = (((D-G)/D)*100).publish(label='% 12 week Change')
    EOF
    secondary_visualization = "Radial"
    sort_by                 = "-sf_metric"
    time_range              = 900
    unit_prefix             = "Metric"

    color_scale {
        color = "red"
        gt    = 70
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 100
    }
    color_scale {
        color = "green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 50
    }
    color_scale {
        color = "yellow"
        gt    = 50
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 70
    }

    legend_options_fields {
        enabled  = false
        property = "cloud.account.id"
    }
    legend_options_fields {
        enabled  = false
        property = "cloud.availability_zone"
    }
    legend_options_fields {
        enabled  = true
        property = "cloud.platform"
    }
    legend_options_fields {
        enabled  = true
        property = "cloud.provider"
    }
    legend_options_fields {
        enabled  = false
        property = "gcp_id"
    }
    legend_options_fields {
        enabled  = true
        property = "host"
    }
    legend_options_fields {
        enabled  = false
        property = "host.id"
    }
    legend_options_fields {
        enabled  = false
        property = "host.name"
    }
    legend_options_fields {
        enabled  = false
        property = "host.type"
    }
    legend_options_fields {
        enabled  = false
        property = "k8s.cluster.name"
    }
    legend_options_fields {
        enabled  = false
        property = "k8s.node.name"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_cluster"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_node"
    }
    legend_options_fields {
        enabled  = false
        property = "kubernetes_node_uid"
    }
    legend_options_fields {
        enabled  = true
        property = "metric_source"
    }
    legend_options_fields {
        enabled  = true
        property = "os.type"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = true
        property = "sf_service"
    }

    viz_options {
        display_name = "% 12 week Change"
        label        = "% 12 week Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "% 12"
        label        = "% 12"
    }
    viz_options {
        display_name = "% 4 week Change"
        label        = "% 4 week Change"
        value_suffix = "%"
    }
    viz_options {
        display_name = "% 4"
        label        = "% 4"
    }
    viz_options {
        display_name = "Today"
        label        = "Today"
        value_suffix = "%"
    }
    viz_options {
        display_name = "cpu.utilization"
        label        = "A"
        value_suffix = "%"
    }
    viz_options {
        display_name = "disk.summary_utilization"
        label        = "C"
        value_suffix = "%"
    }
    viz_options {
        display_name = "memory.utilization"
        label        = "B"
        value_suffix = "%"
    }
}
