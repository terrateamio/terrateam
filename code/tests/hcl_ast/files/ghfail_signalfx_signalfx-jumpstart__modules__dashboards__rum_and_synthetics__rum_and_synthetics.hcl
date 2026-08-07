# signalfx_text_chart.rum_and_synthetics_0:
resource "signalfx_text_chart" "rum_and_synthetics_0" {
    markdown = <<-EOF
        <table width="100%" height="100%" rules="none"><tr><td valign="middle" align="center" bgcolor="#ab006b">
        <font size="6" color="white"> Real-User and Synthetics Test Data </font>
        </td></tr></table>
    EOF
    name     = "Web Vitals"
}
# signalfx_single_value_chart.rum_and_synthetics_1:
resource "signalfx_single_value_chart" "rum_and_synthetics_1" {
    color_by                = "Dimension"
    description             = "p75"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Real-User Page Load Latency"
    program_text            = <<-EOF
        A = data('rum.page_view.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75, by=['app', 'sf_environment']).publish(label='A', enable=False)
        B = (A/1000000000).publish(label='B')
    EOF
    secondary_visualization = "None"
    show_spark_line         = false
    unit_prefix             = "Metric"

    viz_options {
        display_name = "Real-User Latency in Seconds"
        label        = "B"
        value_suffix = "sec"
    }
    viz_options {
        display_name = "rum.page_view.time.ns.p75 - P75 by app,sf_environment"
        label        = "A"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_2:
resource "signalfx_single_value_chart" "rum_and_synthetics_2" {
    color_by                = "Dimension"
    description             = "p75"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Synthetics - Page Load Latency"
    program_text            = <<-EOF
        C = data('synthetics.real_browser.dom_load_time_ms', filter=filter('check', 'RUM-splunk-shop-checkout')).percentile(pct=90, by=['check']).publish(label='C', enable=False)
        E = (C/1000).publish(label='E')
    EOF
    secondary_visualization = "None"
    show_spark_line         = false
    unit_prefix             = "Metric"

    viz_options {
        display_name = "C/1000"
        label        = "E"
        value_suffix = "sec"
    }
    viz_options {
        display_name = "synthetics.real_browser.dom_load_time_ms - P90 by check"
        label        = "C"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_3:
resource "signalfx_single_value_chart" "rum_and_synthetics_3" {
    color_by                = "Scale"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "LCP time RUM"
    program_text            = <<-EOF
        A = data('rum.webvitals_lcp.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75).publish(label='A', enable=False)
        B = (A/1000000000).publish(label='B')
    EOF
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 2.5
    }
    color_scale {
        color = "red"
        gt    = 4
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 6.5
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 2.5
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 4
    }

    viz_options {
        display_name = "LCP in Seconds"
        label        = "B"
        value_suffix = "sec"
    }
    viz_options {
        display_name = "rum.webvitals_lcp.time.ns.p75 - P75"
        label        = "A"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_4:
resource "signalfx_single_value_chart" "rum_and_synthetics_4" {
    color_by                = "Scale"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "LCP - Synthetics Baseline"
    program_text            = <<-EOF
        A = data('synthetics.real_browser.largest_contentful_paint_time_ms', filter=filter('check', 'Homepage-Desktop')).percentile(pct=90, by=['check']).publish(label='A', enable=False)
        B = (A/1000).publish(label='B')
    EOF
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 2.5
    }
    color_scale {
        color = "red"
        gt    = 4
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 6.5
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 2.5
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 4
    }

    viz_options {
        display_name = "LCP in Seconds"
        label        = "B"
        value_suffix = "sec"
    }
    viz_options {
        display_name = "synthetics.real_browser.largest_contentful_paint_time_ms - P90 by check"
        label        = "A"
    }
}
# signalfx_time_chart.rum_and_synthetics_5:
resource "signalfx_time_chart" "rum_and_synthetics_5" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "p75"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Page Load Latency"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = data('rum.page_view.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75, by=['app', 'sf_environment']).publish(label='A', enable=False)
        B = (A/1000000000).publish(label='B')
        C = data('synthetics.real_browser.dom_load_time_ms', filter=filter('check', 'RUM-splunk-shop-checkout')).percentile(pct=90, by=['check']).publish(label='C', enable=False)
        D = (C/1000).publish(label='D')
    EOF
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    axis_left {
        label          = "seconds"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "Real-User Latency in Seconds"
        label        = "B"
    }
    viz_options {
        axis         = "left"
        display_name = "Synthetics Baseline"
        label        = "D"
        plot_type    = "LineChart"
        value_unit   = "Millisecond"
    }
    viz_options {
        axis         = "left"
        display_name = "rum.page_view.time.ns.p75 - P75 by app,sf_environment"
        label        = "A"
    }
    viz_options {
        axis         = "left"
        display_name = "synthetics.real_browser.dom_load_time_ms - P90 by check"
        label        = "C"
    }
}
# signalfx_time_chart.rum_and_synthetics_6:
resource "signalfx_time_chart" "rum_and_synthetics_6" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "LCP (Real-User and Synthetics Baseline)"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = data('rum.webvitals_lcp.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75, by=['app', 'sf_environment']).publish(label='A', enable=False)
        B = (A/1000000000).publish(label='B')
        C = data('synthetics.real_browser.largest_contentful_paint_time_ms', filter=filter('check', 'O11y-Store')).percentile(pct=75, by=['check']).publish(label='C', enable=False)
        D = (C/1000).publish(label='D')
    EOF
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    axis_left {
        label          = "seconds"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "rum.webvitals_lcp.time.ns.p75 - P75 by app,sf_environment"
        label        = "A"
    }
    viz_options {
        axis         = "left"
        display_name = "synthetics.real_browser.largest_contentful_paint_time_ms - P75 by check"
        label        = "C"
    }
    viz_options {
        axis         = "left"
        color        = "blue"
        display_name = "Synthetics Baseline for LCP in Seconds"
        label        = "D"
        plot_type    = "LineChart"
    }
    viz_options {
        axis         = "left"
        color        = "iris"
        display_name = "Real-User LCP in Seconds"
        label        = "B"
        plot_type    = "ColumnChart"
    }
}
# signalfx_time_chart.rum_and_synthetics_7:
resource "signalfx_time_chart" "rum_and_synthetics_7" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Website Traffic"
    on_chart_legend_dimension = "app"
    plot_type                 = "LineChart"
    program_text              = "A = data('rum.page_view.count', filter=filter('app', '*')).sum(by=['app']).publish(label='A')"
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "rum.page_view.count - Sum by app"
        label        = "A"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_8:
resource "signalfx_single_value_chart" "rum_and_synthetics_8" {
    color_by                = "Scale"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "FID Score"
    program_text            = <<-EOF
        A = data('rum.webvitals_fid.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75).publish(label='A', enable=False)
        B = (A/1000000).publish(label='B')
    EOF
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 100
    }
    color_scale {
        color = "red"
        gt    = 300
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 400
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 100
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 300
    }

    viz_options {
        display_name = "FID in milliseconds"
        label        = "B"
        value_suffix = "ms"
    }
    viz_options {
        display_name = "rum.webvitals_fid.time.ns.p75 - P75"
        label        = "A"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_9:
resource "signalfx_single_value_chart" "rum_and_synthetics_9" {
    color_by                = "Scale"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "CLS Score RUM"
    program_text            = "A = data('rum.webvitals_cls.score.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75).publish(label='A')"
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 0.1
    }
    color_scale {
        color = "red"
        gt    = 0.25
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0.5
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 0.1
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0.25
    }

    viz_options {
        display_name = "rum.webvitals_cls.score.p75 - P75"
        label        = "A"
    }
}
# signalfx_time_chart.rum_and_synthetics_10:
resource "signalfx_time_chart" "rum_and_synthetics_10" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "Grouped by app and environment"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Javascript errors per page view (Average)"
    on_chart_legend_dimension = "app"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = data('rum.client_error.count', filter=filter('app', '*') and filter('sf_environment', '*')).sum(by=['app', 'sf_environment']).publish(label='A', enable=False)
        B = data('rum.page_view.count', filter=filter('app', '*') and filter('sf_environment', '*')).sum(by=['app', 'sf_environment']).publish(label='B', enable=False)
        C = (A/B).publish(label='C')
    EOF
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 518400
    unit_prefix               = "Metric"

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "A/B"
        label        = "C"
    }
    viz_options {
        axis         = "left"
        display_name = "rum.client_error.count - Sum by app,sf_environment"
        label        = "A"
    }
    viz_options {
        axis         = "left"
        display_name = "rum.page_view.count - Sum by app,sf_environment"
        label        = "B"
    }
}
# signalfx_time_chart.rum_and_synthetics_11:
resource "signalfx_time_chart" "rum_and_synthetics_11" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "HTTP Error Rate"
    on_chart_legend_dimension = "app"
    plot_type                 = "AreaChart"
    program_text              = <<-EOF
        A = data('rum.resource_request.count', filter=filter('app', '*') and filter('sf_environment', '*')).sum(by=['app', 'sf_environment']).publish(label='A', enable=False)
        C = data('rum.resource_request.count', filter=filter('app', '*') and filter('sf_environment', '*') and filter('sf_error', 'true')).sum(by=['app', 'sf_environment']).publish(label='C', enable=False)
        D = (100*C/A).publish(label='D')
    EOF
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    axis_left {
        label          = "Percentage (%)"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "100*C/A"
        label        = "D"
    }
    viz_options {
        axis         = "left"
        display_name = "rum.resource_request.count - Sum by app,sf_environment"
        label        = "A"
    }
    viz_options {
        axis         = "left"
        display_name = "rum.resource_request.count - Sum by app,sf_environment"
        label        = "C"
    }
}
# signalfx_text_chart.rum_and_synthetics_12:
resource "signalfx_text_chart" "rum_and_synthetics_12" {
    markdown = <<-EOF
        <table width="100%" height="100%" rules="none"><tr><td valign="middle" align="center" bgcolor="#111">
        <font size="6" color="white"> Web Vitals </font>
        </td></tr></table>
    EOF
    name     = "Web Vitals"
}
# signalfx_single_value_chart.rum_and_synthetics_13:
resource "signalfx_single_value_chart" "rum_and_synthetics_13" {
    color_by                = "Dimension"
    is_timestamp_hidden     = false
    max_precision           = 0
    name                    = "synthetics.real_browser.total_blocking_time_ms"
    program_text            = <<-EOF
        A = data('synthetics.real_browser.total_blocking_time_ms', filter=filter('check', 'RUM-splunk-shop-checkout')).publish(label='A', enable=False)
        B = (A/1000).publish(label='B')
    EOF
    secondary_visualization = "None"
    show_spark_line         = false
    unit_prefix             = "Metric"

    viz_options {
        display_name = "A/1000"
        label        = "B"
    }
    viz_options {
        display_name = "synthetics.real_browser.total_blocking_time_ms"
        label        = "A"
    }
}
# signalfx_time_chart.rum_and_synthetics_14:
resource "signalfx_time_chart" "rum_and_synthetics_14" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "p75"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "FID/TBT"
    on_chart_legend_dimension = "app"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = data('rum.webvitals_fid.time.ns.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75, by=['app', 'sf_environment']).publish(label='A', enable=False)
        B = (A/1000000).publish(label='B')
        C = data('synthetics.real_browser.total_blocking_time_ms', filter=filter('check', 'BTubalinal-O11Y-Store')).percentile(pct=90, by=['check']).above(0).publish(label='C', enable=False)
        D = (C/1000).publish(label='D')
    EOF
    show_data_markers         = false
    show_event_lines          = false
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    axis_left {
        label          = "milliseconds"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "rum.webvitals_fid.time.ns.p75 - P75 by app,sf_environment"
        label        = "A"
    }
    viz_options {
        axis         = "left"
        display_name = "synthetics.real_browser.total_blocking_time_ms - P90 by check - Exclude x <= 0"
        label        = "C"
    }
    viz_options {
        axis         = "left"
        color        = "iris"
        display_name = "Real-User Latency in ms"
        label        = "B"
    }
    viz_options {
        axis         = "right"
        color        = "purple"
        display_name = "Synthetics Baseline"
        label        = "D"
        plot_type    = "LineChart"
        value_unit   = "Second"
    }
}
# signalfx_single_value_chart.rum_and_synthetics_15:
resource "signalfx_single_value_chart" "rum_and_synthetics_15" {
    color_by                = "Scale"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "CLS Score"
    program_text            = "A = data('rum.webvitals_cls.score.p75', filter=filter('app', '*') and filter('sf_environment', '*')).percentile(pct=75).publish(label='A')"
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 0.1
    }
    color_scale {
        color = "red"
        gt    = 0.25
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0.5
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 0.1
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 0.25
    }

    viz_options {
        display_name = "rum.webvitals_cls.score.p75 - P75"
        label        = "A"
    }
}
# signalfx_time_chart.rum_and_synthetics_16:
resource "signalfx_time_chart" "rum_and_synthetics_16" {
    axes_include_zero  = false
    axes_precision     = 0
    color_by           = "Dimension"
    description        = "Baseline (P75)"
    disable_sampling   = false
    max_delay          = 0
    minimum_resolution = 0
    name               = "Synthetics | Page Load Time"
    plot_type          = "LineChart"
    program_text       = <<-EOF
        A = data('synthetics.real_browser.dom_load_time_ms', filter=filter('check', 'RUM-splunk-shop-checkout')).percentile(pct=75, by=['check']).publish(label='A', enable=False)
        B = (A/1000).publish(label='B')
    EOF
    show_data_markers  = false
    show_event_lines   = false
    stacked            = false
    time_range         = 900
    unit_prefix        = "Metric"

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "A/1000"
        label        = "B"
    }
    viz_options {
        axis         = "left"
        display_name = "synthetics.real_browser.dom_load_time_ms - P75 by check"
        label        = "A"
    }
}
# signalfx_list_chart.rum_and_synthetics_17:
resource "signalfx_list_chart" "rum_and_synthetics_17" {
    color_by                = "Scale"
    disable_sampling        = false
    hide_missing_values     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "TBT - Synthetics"
    program_text            = <<-EOF
        A = data('synthetics.real_browser.total_blocking_time_ms').percentile(pct=90, by=['check']).publish(label='A', enable=False)
        B = (A).publish(label='B')
    EOF
    secondary_visualization = "Linear"
    time_range              = 900
    unit_prefix             = "Metric"

    color_scale {
        color = "lime_green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 2.5
    }
    color_scale {
        color = "red"
        gt    = 4
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 6.5
    }
    color_scale {
        color = "vivid_yellow"
        gt    = 2.5
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 4
    }

    viz_options {
        display_name = "TBT in ms"
        label        = "B"
        value_suffix = "sec"
    }
    viz_options {
        display_name = "synthetics.real_browser.total_blocking_time_ms - P90 by check"
        label        = "A"
    }
}
# signalfx_dashboard.rum_and_synthetics:
resource "signalfx_dashboard" "rum_and_synthetics" {
    charts_resolution = "default"
    dashboard_group = signalfx_dashboard_group.rumandsynthetics.id
    name              = "Synthetics and RUM"
    time_range        = "-1w"

    chart {
        chart_id = signalfx_list_chart.rum_and_synthetics_17.id
        column   = 6
        height   = 1
        row      = 7
        width    = 6
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_4.id
        column   = 9
        height   = 1
        row      = 1
        width    = 3
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_6.id
        column   = 6
        height   = 1
        row      = 2
        width    = 6
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_1.id
        column   = 0
        height   = 1
        row      = 1
        width    = 3
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_2.id
        column   = 3
        height   = 1
        row      = 1
        width    = 3
    }
    chart {
        chart_id = signalfx_text_chart.rum_and_synthetics_0.id
        column   = 0
        height   = 1
        row      = 0
        width    = 12
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_15.id
        column   = 6
        height   = 1
        row      = 6
        width    = 6
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_14.id
        column   = 0
        height   = 1
        row      = 6
        width    = 6
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_13.id
        column   = 6
        height   = 1
        row      = 5
        width    = 6
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_3.id
        column   = 6
        height   = 1
        row      = 1
        width    = 3
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_9.id
        column   = 9
        height   = 1
        row      = 3
        width    = 3
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_11.id
        column   = 6
        height   = 1
        row      = 4
        width    = 6
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_5.id
        column   = 0
        height   = 1
        row      = 2
        width    = 6
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_7.id
        column   = 0
        height   = 1
        row      = 3
        width    = 6
    }
    chart {
        chart_id = signalfx_text_chart.rum_and_synthetics_12.id
        column   = 0
        height   = 1
        row      = 5
        width    = 3
    }
    chart {
        chart_id = signalfx_single_value_chart.rum_and_synthetics_8.id
        column   = 6
        height   = 1
        row      = 3
        width    = 3
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_10.id
        column   = 0
        height   = 1
        row      = 4
        width    = 6
    }
    chart {
        chart_id = signalfx_time_chart.rum_and_synthetics_16.id
        column   = 0
        height   = 1
        row      = 7
        width    = 6
    }

    variable {
        alias                  = "Application Name (app)"
        apply_if_exist         = false
        property               = "app"
        replace_only           = false
        restricted_suggestions = false
        value_required         = false
        values                 = []
        values_suggested       = []
    }
    variable {
        alias                  = "Environment (environment)"
        apply_if_exist         = false
        property               = "sf_environment"
        replace_only           = true
        restricted_suggestions = false
        value_required         = false
        values                 = []
        values_suggested       = []
    }
}