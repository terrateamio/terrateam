# signalfx_dashboard.TOKEN-USAGE-EXEC:
resource "signalfx_dashboard" "TOKEN-USAGE-EXEC" {
    depends_on = [signalfx_dashboard.Logs-Exec]
    charts_resolution = "default"
    dashboard_group   = signalfx_dashboard_group.exec_dashboard_group.id
    name              = "Token Usage - Exec"
    time_range        = "-15w"

    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_1.id
        column   = 3
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_2.id
        column   = 6
        height   = 2
        row      = 0
        width    = 6
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_3.id
        column   = 0
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_0.id
        column   = 0
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_4.id
        column   = 3
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_7.id
        column   = 0
        height   = 2
        row      = 4
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_8.id
        column   = 3
        height   = 2
        row      = 4
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_6.id
        column   = 9
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_5.id
        column   = 6
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_9.id
        column   = 6
        height   = 2
        row      = 4
        width    = 3
    }
    chart {
        chart_id = signalfx_list_chart.TOKEN-USAGE-EXEC_10.id
        column   = 9
        height   = 2
        row      = 4
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
        alias                  = "tokenName"
        apply_if_exist         = false
        description            = "Token Name"
        property               = "tokenName"
        replace_only           = true
        restricted_suggestions = false
        value_required         = true
        values                 = [
            "*",
        ]
        values_suggested       = []
    }
}

# signalfx_list_chart.TOKEN-USAGE-EXEC_0:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_0" {
    color_by                = "Metric"
    description             = "Token Usage Change Top and Bottom 5 (12 Week Comparison of 7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Token Usage Rate 12 Week Comparison"
    program_text            = <<-EOF
        A = data('sf.org.numBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('12w').mean(over='7d').publish(label='B', enable=False)
        
        AA = data('sf.org.numCustomMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AA', enable=False)
        A1 = data('sf.org.numCustomMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('12w').mean(over='7d').publish(label='A1', enable=False)
        
        AB = data('sf.org.numSyntheticsMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AB', enable=False)
        A2 = data('sf.org.numSyntheticsMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('12w').mean(over='7d').publish(label='A2', enable=False)
        
        AC = data('sf.org.numApmBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AC', enable=False)
        A3 = data('sf.org.numApmBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('12w').mean(over='7d').publish(label='A3', enable=False)
        
        AD = data('sf.org.numResourceMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AD', enable=False)
        A4 = data('sf.org.numResourceMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('12w').mean(over='7d').publish(label='A4', enable=False)
        
        syntheticsTotal = (AB.sum() if AB.count() > 0 else 0).publish(label='synthetics', enable=False)
        syntheticsTotal12w = (A2.sum() if A2.count() > 0 else 0).publish(label='synthetics', enable=False)
        
        total = (A + AA + syntheticsTotal + AC + AD).publish(label='total', enable=False)
        total12w = (B + A1 + syntheticsTotal12w + A3 + A4).publish(label='total', enable=False)
        
        
        topChange = (((total-total12w)/total12w)*100).mean(by=['tokenName']).mean(over='7d').top(count=5).publish(label='topChange', enable=True)
        bottomChange = (((total-total12w)/total12w)*100).mean(by=['tokenName']).mean(over='7d').bottom(count=5).publish(label='bottomChange', enable=True)
    EOF
    refresh_interval        = 3600
    secondary_visualization = "None"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    legend_options_fields {
        enabled  = false
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = true
        property = "tokenName"
    }

    viz_options {
        display_name = "A1"
        label        = "A1"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "A2"
        label        = "A2"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "A3"
        label        = "A3"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "A4"
        label        = "A4"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "bottomChange"
        label        = "bottomChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "sf.org.numApmBundledMetricsByToken"
        label        = "AC"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "sf.org.numCustomMetricsByToken"
        label        = "AA"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "sf.org.numResourceMetricsByToken"
        label        = "AD"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "sf.org.numSyntheticsMetricsByToken"
        label        = "AB"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "synthetics"
        label        = "synthetics"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        color        = "lilac"
        display_name = "Token Usage (-4w)"
        label        = "B"
        value_suffix = "% change"
    }
    viz_options {
        color        = "lilac"
        display_name = "Token Usage"
        label        = "A"
        value_suffix = "% change"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_1:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_1" {
    color_by                = "Scale"
    description             = "Token Usage Rate (MTS) 4 & 12 Week Comparisons Using  1 Day Sums"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Token Usage Rate (MTS) (4 & 12 week comparisons)"
    program_text            = <<-EOF
        C = data('sf.org.numBundledMetricsByToken', rollup='sum').sum(over='1d').sum().publish(label='C')
        D = data('sf.org.numBundledMetricsByToken', rollup='sum').sum(over='1d').sum().timeshift('4w').publish(label='D', enable=False)
        E = data('sf.org.numBundledMetricsByToken', rollup='sum').sum(over='1d').sum().timeshift('12w').publish(label='E', enable=False)
        F = (((C-D)/C)*100).publish(label='F')
        G = (((C-E)/C)*100).publish(label='G')
    EOF
    secondary_visualization = "Radial"
    time_range              = 900
    timezone                = "UTC"
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
    }
    viz_options {
        color        = "lilac"
        display_name = "-4w"
        label        = "D"
    }
    viz_options {
        color        = "lilac"
        display_name = "Today"
        label        = "C"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_2:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_2" {
    color_by                = "Scale"
    description             = "Mean MTS usage by Token Name Using 7 Day Means"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Mean MTS usage(7d) by Token Name"
    program_text            = <<-EOF
        A = data('sf.org.numBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        
        AA = data('sf.org.numCustomMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AA', enable=False)
        
        AB = data('sf.org.numSyntheticsMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AB', enable=False)
        
        AC = data('sf.org.numApmBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AC', enable=False)
        
        AD = data('sf.org.numResourceMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='AD', enable=False)
        
        syntheticsTotal = (AB.sum() if AB.count() > 0 else 0).publish(label='synthetics', enable=False)
        
        total = (A + AA + syntheticsTotal + AC + AD).publish(label='total', enable=True)
        
    EOF
    refresh_interval        = 3600
    secondary_visualization = "None"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 1
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
    }
    color_scale {
        color = "red"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 1
    }

    legend_options_fields {
        enabled  = false
        property = "sf_metric"
    }
    legend_options_fields {
        enabled  = true
        property = "tokenName"
    }
    viz_options {
        display_name = "AA"
        label        = "AA"
    }
    viz_options {
        display_name = "AB"
        label        = "AB"
    }
    viz_options {
        display_name = "AC"
        label        = "AC"
    }
    viz_options {
        display_name = "AD"
        label        = "AD"
    }
    viz_options {
        display_name = "synthetics"
        label        = "synthetics"
    }
    viz_options {
        display_name = "total"
        label        = "total"
        value_suffix = "MTS"
    }
    viz_options {
        color        = "lilac"
        display_name = "A"
        label        = "A"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_3:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_3" {
    color_by                = "Scale"
    description             = "Bundled Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Bundled Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        bundledTotal = (A.sum() if A.count() > 0 else 0).publish(label='bundledTotal', enable=False)
        bundledTotal4w = (B.sum() if B.count() > 0 else 0).publish(label='bundledTotal4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "bundledTotal"
        label        = "bundledTotal"
    }
    viz_options {
        display_name = "bundledTotal4w"
        label        = "bundledTotal4w"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_4:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_4" {
    color_by                = "Scale"
    description             = "Custom Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Custom Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numCustomMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numCustomMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        total = (A.sum() if A.count() > 0 else 0).publish(label='total', enable=False)
        total4w = (B.sum() if B.count() > 0 else 0).publish(label='total4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        display_name = "total4w"
        label        = "total4w"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_5:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_5" {
    color_by                = "Scale"
    description             = "Resource Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Resource Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numResourceMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numResourceMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        total = (A.sum() if A.count() > 0 else 0).publish(label='total', enable=False)
        total4w = (B.sum() if B.count() > 0 else 0).publish(label='total4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        display_name = "total4w"
        label        = "total4w"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_6:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_6" {
    color_by                = "Scale"
    description             = "APM Bundled Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "APM Bundled Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numApmBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numApmBundledMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        total = (A.sum() if A.count() > 0 else 0).publish(label='total', enable=False)
        total4w = (B.sum() if B.count() > 0 else 0).publish(label='total4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        display_name = "total4w"
        label        = "total4w"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_7:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_7" {
    color_by                = "Scale"
    description             = "High Resolution Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "High Resolution Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numHighResolutionMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numHighResolutionMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        total = (A.sum() if A.count() > 0 else 0).publish(label='total', enable=False)
        total4w = (B.sum() if B.count() > 0 else 0).publish(label='total4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        display_name = "total4w"
        label        = "total4w"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_8:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_8" {
    color_by                = "Scale"
    description             = "Synthetics Metrics By Token (MTS) 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Synthetics Metrics By Token (MTS) 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.numSyntheticsMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).mean(over='7d').publish(label='A', enable=False)
        B = data('sf.org.numSyntheticsMetricsByToken', filter=filter('tokenName', '*')).sum(by=['tokenName']).timeshift('4w').mean(over='7d').publish(label='B', enable=False)
        
        total = (A.sum() if A.count() > 0 else 0).publish(label='total', enable=False)
        total4w = (B.sum() if B.count() > 0 else 0).publish(label='total4w', enable=False)
        
        topChange = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').publish(label='topChange', enable=True)
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

    color_scale {
        color = "aquamarine"
        gt    = 340282346638528860000000000000000000000
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0
    }
    color_scale {
        color = "gray"
        gt    = 0
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 340282346638528860000000000000000000000
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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "topChange"
        label        = "topChange"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "total"
        label        = "total"
    }
    viz_options {
        display_name = "total4w"
        label        = "total4w"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_9:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_9" {
    color_by                = "Metric"
    description             = "Logs Received per Day by Token 4 Week Comparison (7 Day Mean)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Logs Received per Day by Token 4 Week Comparison"
    program_text            = <<-EOF
        A = data('sf.org.numLogsReceivedByToken').sum(by=['tokenName']).mean(over='7d').sum(over='1d').publish(label='A', enable=False)
        B = data('sf.org.numLogsReceivedByToken').sum(by=['tokenName']).timeshift('4w').mean(over='7d').sum(over='1d').publish(label='B', enable=False)
        C = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').fill(0).top(5).publish(label='C')
        D = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').fill(0).bottom(5).publish(label='D')
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "C"
        label        = "C"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "D"
        label        = "D"
        value_suffix = "% change"
    }
}
# signalfx_list_chart.TOKEN-USAGE-EXEC_10:
resource "signalfx_list_chart" "TOKEN-USAGE-EXEC_10" {
    color_by                = "Metric"
    description             = "Profiling Logs Received per Day by Token 4 Week Comparisons (7 Day Means)"
    disable_sampling        = false
    hide_missing_values     = false
    max_precision           = 2
    name                    = "Profiling Logs Received per Day by Token 4 Week Comparisons"
    program_text            = <<-EOF
        A = data('sf.org.profiling.numLogsReceivedByToken').sum(by=['tokenName']).mean(over='7d').sum(over='1d').publish(label='A', enable=False)
        B = data('sf.org.profiling.numLogsReceivedByToken').sum(by=['tokenName']).timeshift('4w').mean(over='7d').sum(over='1d').publish(label='B', enable=False)
        C = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').fill(0).top(5).publish(label='C')
        D = (((A-B)/B)*100).mean(by=['tokenName']).mean(over='7d').fill(0).bottom(5).publish(label='D')
    EOF
    secondary_visualization = "Sparkline"
    sort_by                 = "-value"
    time_range              = 900
    timezone                = "UTC"
    unit_prefix             = "Metric"

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
        property = "tokenName"
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "B"
        label        = "B"
    }
    viz_options {
        display_name = "C"
        label        = "C"
        value_suffix = "% change"
    }
    viz_options {
        display_name = "D"
        label        = "D"
        value_suffix = "% change"
    }
}
