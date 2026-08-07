### GENERAL CONFIG
##################
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "4.27.0"
    }
  }
}

# Set informations about where is your Grafana
provider "grafana" {
    url = var.grafana_url
    auth = var.my_token
}


### DATASOURCE
##############
resource "grafana_data_source" "my_datasource" {
  name = "My OpenTofu Datasource"
  type = "grafana-testdata-datasource"
}

### DASHBOARD
#############
resource "grafana_folder" "dashboard_folder" {
  title = "My Terraform-generated folder"
}

resource "grafana_dashboard" "my_dashboard" {
  folder = grafana_folder.dashboard_folder.id # Reuse the folder we created. We call its ID
  config_json = templatefile("${path.module}/my-dashboard.tftpl", { mydatasource-uid = grafana_data_source.my_datasource.uid }) # Use a provided JSON file and update the variable "mydatasource-uid" using the generated ID. I created this dashboard visually in Grafana, then I replaced the datasource's UID by a variable placeholder.
}

### ALERTING
############
resource "grafana_folder" "alert_folder" {
  title = "My Alert Rule Folder"
}

resource "grafana_contact_point" "default_email" {
  name = "grafana-default-email"

  email {
    addresses    = [var.my_email]
  }
}

# How to find easily your alert model ?
# Go to Grafana, create the alert in UI, save it. Go back to edit your alert. You will find a button "Export". It will give you the HCL model
resource "grafana_rule_group" "rule_group_0000" {
  org_id           = 1
  name             = "My alert rule"
  folder_uid       = grafana_folder.alert_folder.uid
  interval_seconds = 300

  rule {
    name      = "Test data"
    condition = "C"

    # Get the timeseries
    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = grafana_data_source.my_datasource.uid
      model          = "{\"datasource\":{\"type\":\"${grafana_data_source.my_datasource.type}\",\"uid\":\"${grafana_data_source.my_datasource.uid}\"},\"intervalMs\":1000,\"max\":100,\"maxDataPoints\":43200,\"refId\":\"A\",\"scenarioId\":\"random_walk\",\"seriesCount\":1}"
    }

    # Look at the last value (or average or max or min). You can't alert on timeseries, you need a single value
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0,0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[]},\"reducer\":{\"params\":[],\"type\":\"avg\"},\"type\":\"query\"}],\"datasource\":{\"name\":\"Expression\",\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    # Treshold. "If greater than X then 1 else 0"
    data {
      ref_id = "C"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[101],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
  }
}