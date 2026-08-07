variable "slo_service_name" {
    type = string
    #Change this service name to an APM service name in your environment
    default = "placeholder-name-add-your-own-name"
}

variable "detector_name" {
   type = string
   #Change this Detector Name as required
   default = "SLO detector"
}

## Create detector to count downtime minutes
resource "signalfx_detector" "slo_downtime_minutes" {

  name        = "${var.slo_service_name} ${var.detector_name}"
  description = "SLx detector based on successful traffic"
  max_delay   = 30
  tags        = ["SLO", "dev"]

  ## Note that if you use these features, you must use a user's
  ## admin key to authenticate the provider, lest Terraform not be able
  ## to modify the detector in the future!

  # authorized_writer_teams = [signalfx_team.mycoolteam.id]
  # authorized_writer_users = ["abc123"]

  program_text = <<-EOF
        filter_ = filter('sf_environment', '*') and filter('sf_service', '${var.slo_service_name}') and filter('sf_kind', 'SERVER', 'CONSUMER') and (not filter('sf_dimensionalized', '*')) and (not filter('sf_serviceMesh', '*'))
        A = data('spans.count', filter=filter_ and filter('sf_error', 'false'), rollup='rate').sum().publish(label='Success', enable=False)
        B = data('spans.count', filter=filter_, rollup='rate').sum().publish(label='All Traffic', enable=False)
        C = combine(100*((A if A is not None else 0)/B)).publish(label='Success Rate %')
        
        constant = const(30)

        ### Force detector to retrigger ever minute when in a breaching state.
        ### This gives us "downtime mintues"
        detect(when(C < 99, duration("30s")), off=when(constant < 100, duration("20s")), mode='split').publish('Success Ratio Detector')
    EOF

  rule {
    description   = "Successful traffic < 99 (downtime minutes)"
    severity      = "Warning"
    detect_label  = "Success Ratio Detector"
    notifications = []
  }    

}


### Create a Dashboard Group for our Dashboards
resource "signalfx_dashboard_group" "slo_dashboard_group" {
  name        = "SLO / SLx Dashboards"
  description = "SLO / SLx Level Dashboards"

  ### Note that if you use these features, you must use a user's
  ### admin key to authenticate the provider, lest Terraform not be able
  ### to modify the dashboard group in the future!
  #authorized_writer_teams = [signalfx_team.mycoolteam.id]
  #authorized_writer_users = ["abc123"]
}


# signalfx_time_chart.SLO-SLx-Investigation_0:
resource "signalfx_time_chart" "SLO-SLx-Investigation_0" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "Downtime minutes over 31 day cycle"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Downtime Minutes (SLO)"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream")
        
        downtime = (alert_stream).sum(cycle='month', cycle_start='1d', partial_values=True).fill().publish(label="Downtime Minutes")
    EOF
    show_data_markers         = true
    show_event_lines          = true
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    event_options {
        display_name = "${var.slo_service_name} ${var.detector_name}"
        label        = "A"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        axis         = "left"
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
        plot_type    = "ColumnChart"
    }
}
# signalfx_single_value_chart.SLO-SLx-Investigation_1:
resource "signalfx_single_value_chart" "SLO-SLx-Investigation_1" {
    color_by                = "Scale"
    description             = "99.99% , 99.5% , and 99% availability in minutes (1month)"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Downtime Minutes (SLO) 1month"
    program_text            = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream", enable=False)
        
        
        downtime = (alert_stream).sum(cycle='month', cycle_start='1d', partial_values=True).fill().publish(label="Downtime Minutes")
        
        ## Break points on the radial above are 99.99% , 99.5% , and 99% availability in minutes
    EOF
    secondary_visualization = "Radial"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 44
    }
    color_scale {
        color = "red"
        gt    = 220
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 438
    }
    color_scale {
        color = "yellow"
        gt    = 44
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 220
    }

    viz_options {
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
    }
}
# signalfx_time_chart.SLO-SLx-Investigation_2:
resource "signalfx_time_chart" "SLO-SLx-Investigation_2" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "Downtime Minutes Budget over 31 day cycle"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Downtime Budget (SLO)"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream")
        
        downtime = (alert_stream).sum(cycle='month', cycle_start='1d', partial_values=True).fill().publish(label="Downtime Minutes", enable=False)
        
        ## 99% uptime is roughly 438 minutes
        budgeted_minutes = const(438)
        
        Total = (budgeted_minutes - downtime).fill().publish(label="Available Budget")
    EOF
    show_data_markers         = true
    show_event_lines          = true
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    event_options {
        display_name = "${var.slo_service_name} ${var.detector_name}"
        label        = "A"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "Available Budget"
        label        = "Available Budget"
    }
    viz_options {
        axis         = "left"
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        axis         = "left"
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
        plot_type    = "ColumnChart"
    }
}
# signalfx_single_value_chart.SLO-SLx-Investigation_3:
resource "signalfx_single_value_chart" "SLO-SLx-Investigation_3" {
    color_by                = "Scale"
    description             = "Downtime Budget Remaining (1month)"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Downtime Budget Remaining (SLO) 1month"
    program_text            = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream", enable=False)
        
        downtime = (alert_stream).sum(cycle='month', cycle_start='1d', partial_values=True).fill().publish(label="Downtime Minutes", enable=False)
                
        ## 99% uptime is roughly 438 minutes
        budgeted_minutes = const(438)
                
        Total = (budgeted_minutes - downtime).fill().publish(label="Available Budget")

    EOF
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 395
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 438
    }
    color_scale {
        color = "red"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 219
    }
    color_scale {
        color = "yellow"
        gt    = 219
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 395
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "Available Budget"
        label        = "Available Budget"
    }
    viz_options {
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
    }
}
# signalfx_time_chart.SLO-SLx-Investigation_4:
resource "signalfx_time_chart" "SLO-SLx-Investigation_4" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "Weekly Downtime minutes over 7 day cycle"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Weekly Downtime Minutes (SLO)"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream")
        
        downtime = (alert_stream).sum(cycle='week', cycle_start='Monday', partial_values=True).fill().publish(label="Downtime Minutes")
    EOF
    show_data_markers         = true
    show_event_lines          = true
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    event_options {
        display_name = "${var.slo_service_name} ${var.detector_name}"
        label        = "A"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        color        = "brown"
        display_name = "alert_stream"
        label        = "alert_stream"
        plot_type    = "ColumnChart"
    }
    viz_options {
        axis         = "left"
        color        = "iris"
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
}
# signalfx_single_value_chart.SLO-SLx-Investigation_5:
resource "signalfx_single_value_chart" "SLO-SLx-Investigation_5" {
    color_by                = "Scale"
    description             = "99.99% , 99.5% , and 99% availability in minutes (1week)"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Weekly Downtime Minutes (SLO) 1week"
    program_text            = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream", enable=False)
        
        downtime = (alert_stream).sum(cycle='week', cycle_start='Monday', partial_values=True).fill().publish(label="Downtime Minutes")
        
        ## Break points on the radial above are 99.99% , 99.5% , and 99% availability in minutes
    EOF
    secondary_visualization = "Radial"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 22
    }
    color_scale {
        color = "red"
        gt    = 55
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 101
    }
    color_scale {
        color = "yellow"
        gt    = 22
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 55
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
    }
}
# signalfx_time_chart.SLO-SLx-Investigation_6:
resource "signalfx_time_chart" "SLO-SLx-Investigation_6" {
    axes_include_zero         = false
    axes_precision            = 0
    color_by                  = "Dimension"
    description               = "Downtime Minutes Budget over 7 day cycle"
    disable_sampling          = false
    max_delay                 = 0
    minimum_resolution        = 0
    name                      = "Weekly Downtime Budget (SLO)"
    on_chart_legend_dimension = "plot_label"
    plot_type                 = "ColumnChart"
    program_text              = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream")
        
        downtime = (alert_stream).sum(cycle='week', cycle_start='Monday', partial_values=True).fill().publish(label="Downtime Minutes", enable=False)
        
        ## 99% uptime is roughly 101 minutes
        budgeted_minutes = const(101)
        
        Total = (budgeted_minutes - downtime).fill().publish(label="Available Budget")
    EOF
    show_data_markers         = true
    show_event_lines          = true
    stacked                   = false
    time_range                = 900
    unit_prefix               = "Metric"

    event_options {
        display_name = "${var.slo_service_name} ${var.detector_name}"
        label        = "A"
    }

    histogram_options {
        color_theme = "red"
    }

    viz_options {
        axis         = "left"
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        axis         = "left"
        color        = "brown"
        display_name = "alert_stream"
        label        = "alert_stream"
        plot_type    = "ColumnChart"
    }
    viz_options {
        axis         = "left"
        color        = "navy"
        display_name = "Available Budget"
        label        = "Available Budget"
    }
}
# signalfx_single_value_chart.SLO-SLx-Investigation_7:
resource "signalfx_single_value_chart" "SLO-SLx-Investigation_7" {
    color_by                = "Scale"
    description             = "Downtime Budget Remaining (1week)"
    is_timestamp_hidden     = false
    max_delay               = 0
    max_precision           = 0
    name                    = "Weekly Downtime Budget Remaining (SLO) 1week"
    program_text            = <<-EOF
        A = alerts(detector_name='${var.slo_service_name} ${var.detector_name}').count().publish(label='A', enable=False)
        alert_stream = (A).sum().fill(0).publish(label="alert_stream", enable=False)
        
        downtime = (alert_stream).sum(cycle='week', cycle_start='Monday', partial_values=True).fill().publish(label="Downtime Minutes", enable=False)
        
        ## 99% uptime is roughly 101 minutes
        budgeted_minutes = const(101)
        
        Total = (budgeted_minutes - downtime).fill().publish(label="Available Budget")
    EOF
    secondary_visualization = "Linear"
    show_spark_line         = false
    unit_prefix             = "Metric"

    color_scale {
        color = "green"
        gt    = 55
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 101
    }
    color_scale {
        color = "yellow"
        gt    = 22
        gte   = 340282346638528860000000000000000000000
        lt    = 340282346638528860000000000000000000000
        lte   = 55
    }
    color_scale {
        color = "red"
        gt    = 340282346638528860000000000000000000000
        gte   = 0
        lt    = 340282346638528860000000000000000000000
        lte   = 22
    }

    viz_options {
        display_name = "A"
        label        = "A"
    }
    viz_options {
        display_name = "Available Budget"
        label        = "Available Budget"
    }
    viz_options {
        display_name = "Downtime Minutes"
        label        = "Downtime Minutes"
    }
    viz_options {
        color        = "green"
        display_name = "alert_stream"
        label        = "alert_stream"
    }
}
# signalfx_dashboard.SLO-SLx-Investigation:
resource "signalfx_dashboard" "SLO-SLx-Investigation" {
    charts_resolution = "default"
    dashboard_group   = signalfx_dashboard_group.slo_dashboard_group.id
    description       = "Default dashboard."
    name              = "${var.slo_service_name} SLO/SLx Investigation Dashboard"
    time_range        = "-31d"

    chart {
        chart_id = signalfx_time_chart.SLO-SLx-Investigation_0.id
        column   = 0
        height   = 2
        row      = 0
        width    = 9
    }
    chart {
        chart_id = signalfx_time_chart.SLO-SLx-Investigation_2.id
        column   = 0
        height   = 2
        row      = 2
        width    = 9
    }
    chart {
        chart_id = signalfx_single_value_chart.SLO-SLx-Investigation_1.id
        column   = 9
        height   = 2
        row      = 0
        width    = 3
    }
    chart {
        chart_id = signalfx_single_value_chart.SLO-SLx-Investigation_3.id
        column   = 9
        height   = 2
        row      = 2
        width    = 3
    }
    chart {
        chart_id = signalfx_time_chart.SLO-SLx-Investigation_6.id
        column   = 0
        height   = 2
        row      = 6
        width    = 9
    }
    chart {
        chart_id = signalfx_time_chart.SLO-SLx-Investigation_4.id
        column   = 0
        height   = 2
        row      = 4
        width    = 9
    }
    chart {
        chart_id = signalfx_single_value_chart.SLO-SLx-Investigation_7.id
        column   = 9
        height   = 2
        row      = 6
        width    = 3
    }
    chart {
        chart_id = signalfx_single_value_chart.SLO-SLx-Investigation_5.id
        column   = 9
        height   = 2
        row      = 4
        width    = 3
    }

}
