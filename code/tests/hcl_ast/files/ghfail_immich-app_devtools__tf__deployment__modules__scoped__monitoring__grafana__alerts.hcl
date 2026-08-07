resource "grafana_rule_group" "rule_group_0000" {
  org_id           = 1
  name             = "Minutely"
  folder_uid       = "example-tf-dashboard"
  interval_seconds = 60

  rule {
    name      = "VMetrics Accessible"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 21600
        to   = 0
      }

      datasource_uid = "36979063-5384-4eb9-8679-565a727cbc13"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"36979063-5384-4eb9-8679-565a727cbc13\"},\"disableTextWrap\":false,\"editorMode\":\"builder\",\"expr\":\"vm_app_uptime_seconds\",\"fullMetaSearch\":false,\"includeNullMetadata\":true,\"instant\":false,\"interval\":\"\",\"intervalMs\":15000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":true,\"refId\":\"A\",\"useBackend\":false}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"lt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "Alerting"
    exec_err_state = "Alerting"
    for            = "1m"
    annotations = {
      __dashboardUid__ = "example-dashboard"
      __panelId__      = "3"
      summary          = "Victoria Metrics is inaccessible from Grafana"
    }
    labels = {
      channel  = "team"
      severity = "1"
    }
    is_paused = false
  }
}
