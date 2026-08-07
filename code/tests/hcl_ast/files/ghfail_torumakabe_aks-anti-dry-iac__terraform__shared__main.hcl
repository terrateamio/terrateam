terraform {
  required_version = "~> 1.11.3"
  # Choose the backend according to your requirements
  # backend "remote" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.24.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = local.subnet_addrs.base_cidr_block
  networks = [
    {
      name     = "aks_blue_node_system"
      new_bits = 8
    },
    {
      name     = "aks_blue_node_user_az1"
      new_bits = 8
    },
    {
      name     = "aks_blue_node_user_az2"
      new_bits = 8
    },
    {
      name     = "aks_blue_node_user_az3"
      new_bits = 8
    },
    {
      name     = "aks_blue_svc_lb"
      new_bits = 8
    },
    {
      name     = "aks_green_node_system"
      new_bits = 8
    },
    {
      name     = "aks_green_node_user_az1"
      new_bits = 8
    },
    {
      name     = "aks_green_node_user_az2"
      new_bits = 8
    },
    {
      name     = "aks_green_node_user_az3"
      new_bits = 8
    },
    {
      name     = "aks_green_svc_lb"
      new_bits = 8
    },
    {
      name     = "appgw"
      new_bits = 8
    },
    {
      name     = "endpoint"
      new_bits = 8
    },
    {
      name     = "aci"
      new_bits = 8
    },
  ]
}

provider "azurerm" {
  use_oidc                        = true
  resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "shared" {
  name     = local.shared_rg.name
  location = local.shared_rg.location
}

resource "azurerm_virtual_network" "default" {
  name                = "vnet-default"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  address_space       = [module.subnet_addrs.base_cidr_block]
}

resource "azurerm_subnet" "aks_blue_node_system" {
  name                 = "snet-aks-blue-node-system"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_blue_node_system"]]
}

resource "azurerm_subnet" "aks_blue_node_user_az" {
  for_each             = toset(["1", "2", "3"])
  name                 = "snet-aks-blue-node-user-az${each.key}"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_blue_node_user_az${each.key}"]]
}

resource "azurerm_subnet" "aks_blue_svc_lb" {
  name                 = "snet-aks-blue-svc-lb"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_blue_svc_lb"]]

}

resource "azurerm_subnet" "aks_green_node_system" {
  name                 = "snet-aks-green-node-system"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_green_node_system"]]
}

resource "azurerm_subnet" "aks_green_node_user_az" {
  for_each             = toset(["1", "2", "3"])
  name                 = "snet-aks-green-node-user-az${each.key}"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_green_node_user_az${each.key}"]]
}

resource "azurerm_subnet" "aks_green_svc_lb" {
  name                 = "snet-aks-green-svc-lb"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks_green_svc_lb"]]
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["appgw"]]
}

resource "azurerm_subnet" "endpoint" {
  name                 = "snet-endpoint"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["endpoint"]]
}

resource "azurerm_subnet" "aci" {
  name                 = "snet-aci"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aci"]]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  // Waiting for delegation
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "azurerm_public_ip" "demoapp" {
  name                = "pip-demoapp"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_application_gateway" "shared" {
  name                = local.agw_name
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  zones = [1, 2, 3]

  gateway_ip_configuration {
    name      = local.agw_settings.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.agw_settings.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.agw_settings.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.demoapp.id
  }

  backend_address_pool {
    name = local.demoapp.agw_settings.backend_address_pool_name
    ip_addresses = [
      for target in var.demoapp.target :
      target == "blue" ?
      cidrhost(azurerm_subnet.aks_blue_svc_lb.address_prefixes[0], 4) :
      cidrhost(azurerm_subnet.aks_green_svc_lb.address_prefixes[0], 4)
    ]
  }

  backend_http_settings {
    name                  = local.demoapp.agw_settings.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 15
    probe_name            = local.demoapp.agw_settings.probe_name
    connection_draining {
      enabled           = true
      drain_timeout_sec = 10
    }
  }

  http_listener {
    name                           = local.demoapp.agw_settings.listener_name
    frontend_ip_configuration_name = local.agw_settings.frontend_ip_configuration_name
    frontend_port_name             = local.agw_settings.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name               = local.demoapp.agw_settings.request_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.demoapp.agw_settings.listener_name
    url_path_map_name  = local.demoapp.agw_settings.url_path_map_name
    priority           = 100
  }

  url_path_map {
    name                               = local.demoapp.agw_settings.url_path_map_name
    default_backend_address_pool_name  = local.demoapp.agw_settings.backend_address_pool_name
    default_backend_http_settings_name = local.demoapp.agw_settings.http_setting_name

    // easy solution for protecting health check endpoint
    path_rule {
      name                        = "black-hole"
      paths                       = ["/healthz"]
      redirect_configuration_name = local.demoapp.agw_settings.redirect_configuration_name
    }
  }

  redirect_configuration {
    name          = local.demoapp.agw_settings.redirect_configuration_name
    redirect_type = "Permanent"
    target_url    = "http://blackhole.example"
  }

  probe {
    name                = local.demoapp.agw_settings.probe_name
    host                = "127.0.0.1"
    protocol            = "Http"
    path                = "/healthz"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }
}

resource "random_password" "redis_password" {
  length  = 16
  special = true
}

# recommend to use managed redis for production
resource "azurerm_container_group" "demoapp_redis" {
  name                = "ci-demoapp-redis"
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]
  exposed_port {
    port     = 6379
    protocol = "TCP"
  }
  restart_policy = "Always"
  os_type        = "Linux"

  container {
    name   = "redis"
    image  = "ghcr.io/torumakabe/redis:7.4"
    cpu    = "1.0"
    memory = "1.0"

    ports {
      port     = 6379
      protocol = "TCP"
    }

    environment_variables = {
      "REDIS_PASSWORD" = random_password.redis_password.result
    }
  }
}

resource "azurerm_private_dns_zone" "demoapp_internal_shared" {
  name                = "shared.${var.demoapp.domain}"
  resource_group_name = azurerm_resource_group.shared.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "demoapp_internal_shared" {
  name                  = "pdnsz-link-demoapp-internal-shared"
  resource_group_name   = azurerm_resource_group.shared.name
  private_dns_zone_name = azurerm_private_dns_zone.demoapp_internal_shared.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_dns_a_record" "demoapp_redis" {
  name                = "redis"
  zone_name           = azurerm_private_dns_zone.demoapp_internal_shared.name
  resource_group_name = azurerm_resource_group.shared.name
  ttl                 = 300
  records             = [azurerm_container_group.demoapp_redis.ip_address]
}

resource "azurerm_key_vault" "demoapp" {
  name                      = local.demoapp.key_vault.name
  location                  = azurerm_resource_group.shared.location
  resource_group_name       = azurerm_resource_group.shared.name
  tenant_id                 = local.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = false

  network_acls {
    bypass         = "None"
    default_action = "Deny"
    ip_rules       = local.demoapp.key_vault.ip_rules
  }
}

resource "azurerm_role_assignment" "kv_demoapp_admin_to_current_client" {
  scope = azurerm_key_vault.demoapp.id
  // role_definition_name = "Key Vault Administrator"
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
  principal_id       = local.current_client.object_id

  // Waiting for Azure AD preparation
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_key_vault_secret" "demoapp_redis_server" {
  depends_on = [
    azurerm_role_assignment.kv_demoapp_admin_to_current_client
  ]
  name         = "redis-server"
  value        = "${azurerm_private_dns_a_record.demoapp_redis.fqdn}:6379"
  key_vault_id = azurerm_key_vault.demoapp.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "demoapp_redis_password" {
  depends_on = [
    azurerm_role_assignment.kv_demoapp_admin_to_current_client
  ]
  name         = "redis-password"
  value        = random_password.redis_password.result
  key_vault_id = azurerm_key_vault.demoapp.id
  content_type = "text/plain"
}


resource "azurerm_private_dns_zone" "demoapp_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.shared.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "demoapp_kv" {
  name                  = "pdnsz-link-demoapp-kv"
  resource_group_name   = azurerm_resource_group.shared.name
  private_dns_zone_name = azurerm_private_dns_zone.demoapp_kv.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_endpoint" "demoapp_kv" {
  name                = "pe-demoapp-kv"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  subnet_id           = azurerm_subnet.endpoint.id

  private_dns_zone_group {
    name                 = "pdnsz-group-demoapp-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.demoapp_kv.id]
  }

  private_service_connection {
    name                           = "pe-connection-demoapp-kv"
    private_connection_resource_id = azurerm_key_vault.demoapp.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_monitor_workspace" "prometheus_shared" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  name                = var.prometheus_grafana.workspace_name
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
}

resource "azurerm_monitor_data_collection_endpoint" "amw_prometheus_shared" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  name                = var.prometheus_grafana.data_collection_endpoint_name
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "amw_prometheus_shared" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  name                        = var.prometheus_grafana.data_collection_rule_name
  resource_group_name         = azurerm_resource_group.shared.name
  location                    = azurerm_resource_group.shared.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.amw_prometheus_shared["1"].id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus_shared["1"].id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }


  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }
}

// Reference: https://github.com/Azure/prometheus-collector/blob/main/AddonTerraformTemplate/main.tf
resource "azurerm_monitor_alert_prometheus_rule_group" "amw_prometheus_shared_node" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  name                = "node"
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.prometheus_shared["1"].id]

  rule {
    enabled    = true
    record     = "instance:node_num_cpu:sum"
    expression = <<EOF
count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_cpu_utilisation:rate5m"
    expression = <<EOF
1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_load1_per_cpu:ratio"
    expression = <<EOF
(  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_memory_utilisation:ratio"
    expression = <<EOF
1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})
EOF
  }
  rule {
    enabled = true

    record     = "instance:node_vmstat_pgmajfault:rate5m"
    expression = <<EOF
rate(node_vmstat_pgmajfault{job="node"}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_seconds:rate5m"
    expression = <<EOF
rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
    expression = <<EOF
rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))
EOF
  }
}

// Reference: https://github.com/Azure/prometheus-collector/blob/main/AddonTerraformTemplate/main.tf
resource "azurerm_monitor_alert_prometheus_rule_group" "amw_prometheus_shared_kubernetes" {
  for_each            = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])
  name                = "kubernetes"
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.prometheus_shared["1"].id]

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
    expression = <<EOF
sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job="cadvisor", image!=""}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_working_set_bytes"
    expression = <<EOF
container_memory_working_set_bytes{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_rss"
    expression = <<EOF
container_memory_rss{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_cache"
    expression = <<EOF
container_memory_cache{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_swap"
    expression = <<EOF
container_memory_swap{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
    expression = <<EOF
kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_requests:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
    expression = <<EOF
kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
    expression = <<EOF
kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_limits:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
    expression = <<EOF
kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~"Pending|Running"} == 1) )
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job="kube-state-metrics", owner_kind="ReplicaSet"},      "replicaset", "$1", "owner_name", "(.*)"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job="kube-state-metrics"}      )    ),    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "deployment"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="DaemonSet"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "daemonset"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="StatefulSet"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "statefulset"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="Job"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "job"
    }
  }
  rule {
    enabled    = true
    record     = ":node_memory_MemAvailable_bytes:sum"
    expression = <<EOF
sum(  node_memory_MemAvailable_bytes{job="node"} or  (    node_memory_Buffers_bytes{job="node"} +    node_memory_Cached_bytes{job="node"} +    node_memory_MemFree_bytes{job="node"} +    node_memory_Slab_bytes{job="node"}  )) by (cluster)
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:node_cpu:ratio_rate5m"
    expression = <<EOF
sum(rate(node_cpu_seconds_total{job="node",mode!="idle",mode!="iowait",mode!="steal"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job="node"}) by (cluster, instance, cpu)) by (cluster)
EOF
  }
}

resource "azurerm_dashboard_grafana" "shared" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  name                              = "${var.prefix}-grafana-shared"
  resource_group_name               = azurerm_resource_group.shared.name
  location                          = azurerm_resource_group.shared.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true
  grafana_major_version             = 10

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus_shared["1"].id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "grafana_prom_monitoring_data_reader" {
  for_each = var.prometheus_grafana.enabled ? toset(["1"]) : toset([])

  scope                = azurerm_monitor_workspace.prometheus_shared["1"].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.shared["1"].identity[0].principal_id
}

/* Just a sample of Azure Policy assignment. It is recommended to assign it in the management group to take advantage of inheritance and avoid duplicate assignments in the subscription.

data "azurerm_policy_definition" "k8s_container_no_privilege" {
  name = "95edb821-ddaf-4404-9732-666045e056b4"
}

resource "azurerm_subscription_policy_assignment" "k8s_container_no_privilege" {
  name                 = "k8s-container-no-privilege"
  policy_definition_id = data.azurerm_policy_definition.k8s_container_no_privilege.id
  subscription_id      = local.current_client.subscription_id

  parameters = <<PARAMETERS
    {
      "effect": {
        "value": "deny"
      },
      "excludedNamespaces": {
        "value":
        [
          "kube-system",
          "gatekeeper-system",
          "chaos-testing",
          "azure-arc"
        ]
      },
      "namespaces": {
        "value": []
      },
      "labelSelector": {
        "value": {}
      },
      "excludedContainers": {
        "value": []
      }
    }
PARAMETERS
}
*/
