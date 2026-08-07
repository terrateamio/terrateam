# CloudWatch Dashboard for AWS Network Firewall

resource "aws_cloudwatch_dashboard" "firewall_dashboard" {
  dashboard_name = "${var.firewall_name}-dashboard-tf"

  dashboard_body = jsonencode({
    widgets = concat([
      # Overview Section
      {
        height = 2
        width  = 24
        y      = 0
        x      = 0
        type   = "text"
        properties = {
          markdown   = "# Overview\n[button:primary:Firewall Console](${local.console_url}/vpc/home?region=${data.aws_region.current.name}#NetworkFirewallDetails:arn=${local.arn_pattern}_network-firewall_${data.aws_region.current.name}_${data.aws_caller_identity.current.account_id}_firewall~${var.firewall_name}) [button:Troubleshooting](https://docs.aws.amazon.com/network-firewall/latest/developerguide/troubleshooting.html) [button:re&#58;Post](https://repost.aws/search/content?globalSearch=network%20firewall)"
          background = "transparent"
        }
      },

      # Firewall Endpoints Section Header
      {
        height = 1
        width  = 24
        y      = 2
        x      = 0
        type   = "text"
        properties = {
          markdown   = "# Firewall Endpoints"
          background = "transparent"
        }
      },

      # Firewall Endpoint ENI Metrics
      {
        height = 7
        width  = 6
        y      = 3
        x      = 0
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH(' Namespace=\"AWS/PrivateLinkEndpoints\" ${local.subnet_query_string}', 'Sum', 300)"
              label      = "$${!PROP('Dim.VPC Endpoint Id')}  $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 300
          title   = "Firewall Endpoint ENI (GWLBe/VPCe) Metrics"
          legend = {
            position = "bottom"
          }
        }
      },

      # Per Endpoint Utilization
      {
        height = 7
        width  = 6
        y      = 3
        x      = 6
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "((m1/300)/.008)"
              label      = "$${!PROP('Dim.VPC Endpoint Id')}"
              id         = "e1"
              period     = 300
              stat       = "Sum"
              region     = data.aws_region.current.name
            }],
            [{
              expression = "SEARCH('Namespace=\"AWS/PrivateLinkEndpoints\" ${local.subnet_query_string} MetricName=\"BytesProcessed\"', 'Sum', 300)"
              label      = "Expression1"
              id         = "m1"
              region     = data.aws_region.current.name
              visible    = false
            }]
          ]
          view    = "gauge"
          stacked = true
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 60
          title   = "Per Endpoint Utilization Gbps"
          yAxis = {
            left = {
              min = 0
              max = 100000000000
            }
          }
          setPeriodToTimeRange = false
          sparkline            = true
          trend                = true
        }
      },

      # Active Connections
      {
        height = 7
        width  = 6
        y      = 3
        x      = 12
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/PrivateLinkEndpoints\" ${local.subnet_query_string} MetricName=\"ActiveConnections\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.VPC Endpoint Id')}  $${!PROP('MetricName')}"
              id         = "m1"
              region     = data.aws_region.current.name
              visible    = true
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          period    = 300
          stat      = "Sum"
          title     = "ActiveConnections"
        }
      },

      # Bytes Processed
      {
        height = 7
        width  = 6
        y      = 3
        x      = 18
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/PrivateLinkEndpoints\" ${local.subnet_query_string} MetricName=\"BytesProcessed\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.VPC Endpoint Id')}  $${!PROP('MetricName')}"
              id         = "m2"
              region     = data.aws_region.current.name
              visible    = true
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          period    = 300
          stat      = "Sum"
          title     = "BytesProcessed"
        }
      },

      # Firewall Engines Section Header
      {
        height = 1
        width  = 24
        y      = 10
        x      = 0
        type   = "text"
        properties = {
          markdown   = "# Firewall Engines"
          background = "transparent"
        }
      },

      # Stateless Section Header
      {
        height = 1
        width  = 24
        y      = 11
        x      = 0
        type   = "text"
        properties = {
          markdown   = "## Stateless"
          background = "transparent"
        }
      },

      # Stateless Engine Metrics
      {
        height = 7
        width  = 6
        y      = 12
        x      = 0
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateless\"', 'Sum')"
              label      = ""
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 300
          title   = "Stateless Engine Metrics"
          legend = {
            position = "bottom"
          }
        }
      },

      # Stateless Passed Packets
      {
        height = 7
        width  = 6
        y      = 12
        x      = 6
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateless\" MetricName=\"PassedPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          title     = "Stateless Passed Packets"
          period    = 300
          stat      = "Sum"
        }
      },

      # Stateless Dropped Packets - Rule Action
      {
        height = 7
        width  = 6
        y      = 12
        x      = 12
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateless\" MetricName=\"DroppedPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          title     = "Stateless Dropped Packets - Rule Action"
          period    = 300
          stat      = "Sum"
        }
      },

      # Stateless Dropped Packets - Other
      {
        height = 7
        width  = 6
        y      = 12
        x      = 18
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateless\" MetricName=Other OR Invalid', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          title     = "Stateless Dropped Packets - Other"
          period    = 300
          stat      = "Sum"
        }
      },

      # Stateful Section Header
      {
        height = 1
        width  = 24
        y      = 19
        x      = 0
        type   = "text"
        properties = {
          markdown   = "## Stateful"
          background = "transparent"
        }
      },

      # Stateful Engine Metrics
      {
        height = 7
        width  = 6
        y      = 20
        x      = 0
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateful\"', 'Sum')"
              label      = ""
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 300
          title   = "Stateful Engine Metrics"
        }
      },

      # Stateful Passed Packets
      {
        height = 7
        width  = 6
        y      = 20
        x      = 6
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateful\" MetricName=\"PassedPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          period    = 300
          stat      = "Sum"
          title     = "Stateful Passed Packets"
        }
      },

      # Stateful Dropped Packets
      {
        height = 7
        width  = 6
        y      = 20
        x      = 12
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateful\" MetricName=\"DroppedPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          period    = 300
          stat      = "Sum"
          title     = "Stateful Dropped Packets"
        }
      },

      # Stateful Rejected Packets
      {
        height = 7
        width  = 6
        y      = 20
        x      = 18
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" Engine=\"Stateful\" MetricName=\"RejectedPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          sparkline = true
          view      = "singleValue"
          region    = data.aws_region.current.name
          period    = 300
          stat      = "Sum"
          title     = "Stateful Rejected Packets"
        }
      },

      # TLS Inspection
      {
        height = 7
        width  = 6
        y      = 27
        x      = 0
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" MetricName=TLS', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 300
          title   = "TLS Inspection"
        }
      },

      # Stream Exception Policy Packets
      {
        height = 7
        width  = 6
        y      = 27
        x      = 6
        type   = "metric"
        properties = {
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"AWS/NetworkFirewall\" FirewallName=\"${var.firewall_name}\" MetricName=\"StreamExceptionPolicyPackets\"', 'Sum', 300)"
              label      = "$${!PROP('Dim.AvailabilityZone')} $${!PROP('MetricName')}"
              id         = "e1"
              region     = data.aws_region.current.name
            }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          stat    = "Sum"
          period  = 300
          title   = "Stream Exception Policy Packets"
        }
      },

      # Top Long-Lived TCP Flows
      {
        height = 7
        width  = 6
        y      = 27
        x      = 12
        type   = "metric"
        properties = {
          period = 60
          insightRule = {
            maxContributorCount = 10
            orderBy             = "Sum"
            ruleName            = aws_cloudwatch_contributor_insight_rule.top_long_lived_tcp_flows.rule_name
          }
          stacked = false
          view    = "timeSeries"
          yAxis = {
            left = {
              showUnits = false
            }
            right = {
              showUnits = false
            }
          }
          region = data.aws_region.current.name
          title  = "Top Long-Lived TCP Flows - Age > 350s"
          legend = {
            position = "right"
          }
        }
      },

      # Top TCP Flows - SYN Without SYN-ACK
      {
        height = 7
        width  = 6
        y      = 27
        x      = 18
        type   = "metric"
        properties = {
          period = 60
          insightRule = {
            maxContributorCount = 10
            orderBy             = "Sum"
            ruleName            = aws_cloudwatch_contributor_insight_rule.top_tcp_syn_without_synack.rule_name
          }
          stacked = false
          view    = "timeSeries"
          yAxis = {
            left = {
              showUnits = false
            }
            right = {
              showUnits = false
            }
          }
          region = data.aws_region.current.name
          title  = "Top TCP Flows - SYN Without SYN-ACK"
          legend = {
            position = "right"
          }
        }
      }
    ], local.additional_widgets)
  })

  depends_on = [
    aws_cloudwatch_contributor_insight_rule.top_blocked_tls_sni
  ]
}