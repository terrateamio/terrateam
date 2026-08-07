locals {
  postfix   = var.name_postfix != "" ? var.name_postfix : random_pet.deploy.id
  domain    = var.cf_domain_name == "" ? data.hsdp_config.cf[0].domain : var.cf_domain_name
  hostnames = length(var.hostnames) == 0 ? ["kong-${random_pet.deploy.id}"] : var.hostnames
}

resource "random_pet" "deploy" {
}

data "hsdp_config" "cf" {
  count   = var.cf_domain_name == "" ? 1 : 0
  service = "cf"
}

data "cloudfoundry_org" "org" {
  name = var.cf_org_name
}

data "cloudfoundry_space" "space" {
  org  = data.cloudfoundry_org.org.id
  name = var.cf_space_name
}

data "cloudfoundry_domain" "domain" {
  name = local.domain
}

data "cloudfoundry_domain" "internal_domain" {
  name = "apps.internal"
}

resource "cloudfoundry_app" "kong" {
  name         = "tf-kong-${local.postfix}"
  space        = data.cloudfoundry_space.space.id
  memory       = var.memory
  disk_quota   = var.disk
  docker_image = var.kong_image
  docker_credentials = {
    username = var.docker_username
    password = var.docker_password
  }
  lifecycle {
    ignore_changes = [instances]
  }
  strategy          = var.strategy
  health_check_type = "process"
  command           = var.start_command != "" ? var.start_command : (var.enable_postgres ? "/entrypoint.sh /usr/local/bin/kong migrations bootstrap && /entrypoint.sh /usr/local/bin/kong migrations up && /entrypoint.sh /usr/local/bin/kong migrations finish && /entrypoint.sh kong docker-start" : "/entrypoint.sh kong docker-start")
  environment = merge({
    KONG_PLUGINS                = join(",", var.kong_plugins)
    KONG_TRUSTED_IPS            = "0.0.0.0/0"
    KONG_REAL_IP_HEADER         = "X-Forwarded-For"
    KONG_REAL_IP_RECURSIVE      = "on"
    KONG_PROXY_LISTEN           = "0.0.0.0:8080 reuseport backlog=16384,0.0.0.0:8000 reuseport backlog=16384,0.0.0.0:8443 http2 ssl reuseport backlog=16384,0.0.0.0:8444 http2 ssl reuseport backlog=16384"
    KONG_ADMIN_LISTEN           = "0.0.0.0:8001"
    KONG_NGINX_WORKER_PROCESSES = var.kong_nginx_worker_processes
    }, var.enable_postgres ? {
    KONG_DATABASE      = "postgres"
    KONG_PG_USER       = module.postgres[0].credentials.username
    KONG_PG_PASSWORD   = module.postgres[0].credentials.password
    KONG_PG_HOST       = module.postgres[0].credentials.hostname
    KONG_PG_DATABASE   = module.postgres[0].credentials.db_name
    KONG_PG_SSL        = "on"
    KONG_PG_SSL_VERIFY = "off"
    } : {
    KONG_DATABASE                  = "off"
    KONG_DECLARATIVE_CONFIG_STRING = var.kong_declarative_config_string
  }, var.environment)


  dynamic "routes" {
    for_each = {
      for i, h in local.hostnames : "${i}" => h
    }

    content {
      route = cloudfoundry_route.kong[routes.key].id
    }
  }


  routes {
    route = cloudfoundry_route.kong_internal.id
  }

  labels = {
    "variant.tva/exporter"   = true
    "variant.tva/rules"      = true
    "variant.tva/autoscaler" = length(var.kong_autoscaler_config) > 0
  }
  annotations = {
    "variant.autoscaler.json"           = jsonencode(var.kong_autoscaler_config)
    "prometheus.exporter.instance_name" = "${data.cloudfoundry_org.org.name}.${data.cloudfoundry_space.space.name}.kong-${local.postfix}-$${1}"
    "prometheus.exporter.port"          = "8001"
    "prometheus.exporter.path"          = "/metrics"
    "prometheus.rules.json" = jsonencode([{
      alert = "KongDataStoreReachable"
      expr  = "kong_datastore_reachable < 1"
      for   = "5m"
      labels = {
        severity = "critical"
      }
      annotations = {
        summary     = "Instance {{ $labels.instance }} data store probably not reachable"
        description = "{{ $labels.instance }} data store is not reachable for 5 minutes or longer"
      }
    }])
  }
}

module "postgres" {
  count       = var.enable_postgres ? 1 : 0
  source      = "philips-labs/postgres-service/hsdp"
  version     = "0.3.0"
  cf_space_id = data.cloudfoundry_space.space.id
  plan        = var.db_plan
}

resource "cloudfoundry_route" "kong" {
  for_each = {
    for i, h in local.hostnames : "${i}" => h
  }

  domain   = data.cloudfoundry_domain.domain.id
  space    = data.cloudfoundry_space.space.id
  hostname = each.value
}

resource "cloudfoundry_route" "kong_internal" {
  domain   = data.cloudfoundry_domain.internal_domain.id
  space    = data.cloudfoundry_space.space.id
  hostname = "tf-kong-${local.postfix}"
}

resource "cloudfoundry_network_policy" "kong" {
  count = length(var.network_policies) > 0 ? 1 : 0

  dynamic "policy" {
    for_each = [for p in var.network_policies : {
      destination_app = p.destination_app
      port            = p.port
      protocol        = p.protocol
    }]
    content {
      source_app      = cloudfoundry_app.kong.id_bg
      destination_app = policy.value.destination_app
      protocol        = policy.value.protocol == "" ? "tcp" : policy.value.protocol
      port            = policy.value.port
    }
  }
}
