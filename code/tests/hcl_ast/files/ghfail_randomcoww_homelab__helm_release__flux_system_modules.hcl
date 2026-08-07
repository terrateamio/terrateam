# Load balancer

module "kube-vip" {
  source    = "./modules/kube_vip"
  name      = "kube-vip"
  namespace = "kube-system"
  images = {
    kube_vip = local.container_images_digest.kube_vip
  }
  ports = {
    apiserver        = local.host_ports.apiserver,
    kube_vip_metrics = local.host_ports.kube_vip_metrics,
    kube_vip_health  = local.host_ports.kube_vip_health,
  }
  bgp_as     = local.ha.bgp_as
  bgp_peeras = local.ha.bgp_as
  bgp_neighbor_ips = [
    for _, host in local.members.gateway :
    cidrhost(local.networks.service.prefix, host.netnum)
  ]
  apiserver_ip      = local.services.apiserver.ip
  service_interface = "phy-service"
  affinity = {
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            matchExpressions = [
              {
                key      = "node-role.kubernetes.io/control-plane"
                operator = "Exists"
              },
            ]
          },
        ]
      }
    }
  }
}

# internal s3

resource "random_password" "minio-access-key-id" {
  length  = 30
  special = false
}

resource "random_password" "minio-secret-access-key" {
  length  = 30
  special = false
}

module "minio" {
  source    = "./modules/minio"
  name      = local.endpoints.minio.name
  namespace = local.endpoints.minio.namespace
  images = {
    nginx = local.container_images_digest.nginx
    minio = {
      repository = regex(local.container_image_regex, local.container_images.minio).depName
      tag        = regex(local.container_image_regex, local.container_images.minio).tag
    }
  }
  ports = {
    minio   = local.service_ports.minio
    metrics = local.service_ports.metrics
  }
  minio_credentials = {
    access_key_id     = random_password.minio-access-key-id.result
    secret_access_key = random_password.minio-secret-access-key.result
  }
  cluster_domain     = local.domains.kubernetes
  ca                 = data.terraform_remote_state.host.outputs.internal_ca
  service_hostname   = local.endpoints.minio.service
  service_ip         = local.services.minio.ip
  cluster_service_ip = local.services.cluster_minio.ip
}

# internal registry

module "registry" {
  source    = "./modules/registry"
  name      = local.endpoints.registry.name
  namespace = local.endpoints.registry.namespace
  replicas  = 2
  images = {
    registry = local.container_images_digest.registry
  }
  ports = {
    registry = local.service_ports.registry
    metrics  = local.service_ports.metrics
  }
  ca                      = data.terraform_remote_state.host.outputs.internal_ca
  loadbalancer_class_name = "kube-vip.io/kube-vip-class"

  minio_endpoint      = "${local.services.cluster_minio.ip}:${local.service_ports.minio}"
  minio_bucket        = "registry"
  minio_bucket_prefix = "/"
  minio_access_secret = local.minio_users.registry.secret
  service_hostname    = local.endpoints.registry.service
  service_ip          = local.services.registry.ip
  gateway_ref = {
    name      = local.endpoints.traefik.name
    namespace = local.endpoints.traefik.namespace
  }
}

# cert-manager

module "cert-manager-issuer-acme-prod-secret" {
  source  = "../modules/secret"
  name    = local.kubernetes.cert_issuers.acme_prod
  app     = "cert-issuer"
  release = "0.1.0"
  data = merge({
    "tls.key"        = chomp(data.terraform_remote_state.sr.outputs.letsencrypt.private_key_pem)
    cloudflare-token = data.terraform_remote_state.sr.outputs.cloudflare_dns_api_token
  })
}

module "cert-manager-issuer-ca-internal-secret" {
  source  = "../modules/secret"
  name    = local.kubernetes.cert_issuers.ca_internal
  app     = "cert-issuer"
  release = "0.1.0"
  data = merge({
    "tls.crt" = chomp(data.terraform_remote_state.host.outputs.internal_ca.cert_pem)
    "tls.key" = chomp(data.terraform_remote_state.host.outputs.internal_ca.private_key_pem)
  })
}

# Generic device plugin

module "device-plugin" {
  source    = "./modules/device_plugin"
  name      = "device-plugin"
  namespace = "kube-system"
  images = {
    device_plugin = local.container_images_digest.device_plugin
  }
  ports = {
    device_plugin_metrics = local.service_ports.metrics
  }
  args = [
    "--device",
    yamlencode({
      name = "rfkill"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/rfkill"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "kvm"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/kvm"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "fuse"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/fuse"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "ntsync"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/ntsync"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "uinput"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/uinput"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "input"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/input"
              type = "Mount"
            },
          ]
        },
      ]
    }),
    "--device",
    yamlencode({
      name = "tty"
      groups = [
        {
          count = 8
          paths = [
            {
              path = "/dev/tty0"
            },
            {
              path = "/dev/tty1"
            },
          ]
        },
      ]
    }),
  ]
  kubelet_root_path = local.kubernetes.kubelet_root_path
}

# DHCP

module "kea" {
  source    = "./modules/kea"
  name      = local.endpoints.kea.name
  namespace = local.endpoints.kea.namespace
  images = {
    kea  = local.container_images_digest.kea
    ipxe = local.container_images_digest.ipxe
  }
  service_ips = [
    local.services.cluster_kea_primary.ip,
    local.services.cluster_kea_secondary.ip,
  ]
  ports = {
    kea_peer    = local.host_ports.kea_peer
    kea_metrics = local.host_ports.kea_metrics
    ipxe        = local.host_ports.ipxe
    ipxe_tftp   = local.host_ports.ipxe_tftp
  }
  ipxe_boot_file_name  = "ipxe.efi"
  ipxe_script_base_url = "https://${local.services.minio.ip}:${local.service_ports.minio}/boot/ipxe-"
  networks = [
    {
      prefix = local.networks.lan.prefix
      routers = [
        local.services.gateway.ip,
      ]
      domain_name_servers = [
        local.services.k8s_gateway.ip,
      ]
      domain_search = [
        local.domains.kubernetes,
        local.domains.public,
      ]
      classless_static_route = [
        # allow local access to these from clients that set default route over VPN
        for _, prefix in distinct([
          local.networks[local.services.apiserver.network.name].prefix,
          local.networks.service.prefix,
          local.networks.kubernetes_service.prefix,
        ]) :
        "${prefix} - ${local.services.gateway.ip}"
      ]
      mtu = lookup(local.networks.lan, "mtu", 1500)
    },
    {
      prefix = local.networks.service.prefix
      mtu    = lookup(local.networks.service, "mtu", 1500)
    },
  ]
  timezone = local.timezone
}

# Tailscale remote access

module "tailscale" {
  source    = "./modules/tailscale"
  name      = "tailscale"
  namespace = "tailscale"
  replicas  = 2
  images = {
    tailscale = local.container_images_digest.tailscale
  }
  tailscale_auth_key = data.terraform_remote_state.sr.outputs.tailscale_auth_key
  extra_envs = [
    {
      name  = "TS_ACCEPT_DNS"
      value = false
    },
    {
      name  = "TS_DEBUG_FIREWALL_MODE"
      value = "nftables"
    },
    {
      name = "TS_EXTRA_ARGS"
      value = join(",", [
        "--advertise-exit-node",
      ])
    },
    {
      name = "TS_ROUTES"
      value = join(",", distinct([
        local.networks[local.services.apiserver.network.name].prefix,
        local.networks.service.prefix,
        local.networks.kubernetes_service.prefix,
      ]))
    },
  ]
}

# prometheus

module "prometheus" {
  source    = "./modules/prometheus"
  name      = local.endpoints.prometheus.name
  namespace = local.endpoints.prometheus.namespace
  images = {
    thanos = local.container_images_digest.thanos
  }
  scrape_configs = yamlencode([
    {
      job_name = "cri-o"
      scheme   = "https"
      tls_config = {
        ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      }
      kubernetes_sd_configs = [
        {
          role = "node"
        },
      ]
      relabel_configs = [
        {
          source_labels = ["__address__"]
          regex         = "([^:]+):\\d+$"
          target_label  = "__address__"
          replacement   = "$1:${local.host_ports.crio_metrics}"
        },
      ]
    },
  ])
  server_files = {
    "alerting_rules.yml" = {
      groups = [
        {
          name = "kube-apiserver"
          rules = [
            {
              alert = "KubeAPIDown"
              expr  = <<-EOF
              sum(up{job="kubernetes-api-servers"}) < 2
              or
              absent(up{job="kubernetes-api-servers"})
              EOF
              for   = "90s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "kube-apiserver instance down"
                description = <<-EOF
                Kube-apiserver instances are unreachable.
                Instances affected: {{ $labels.instance }}
                EOF
              }
            },
            {
              alert = "KubeAPIErrorRateHigh"
              expr  = <<-EOF
              sum by (instance) (
                rate(apiserver_request_total{job="kubernetes-api-servers", code=~"5.."}[2m])
              )
              /
              sum by (instance) (
                rate(apiserver_request_total{job="kubernetes-api-servers"}[2m])
              ) > 0.05
              EOF
              for   = "3m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "High error rate on kube-apiserver"
                description = <<-EOF
                Instance {{ $labels.instance }} is returning >5% 5xx errors.
                Cluster may be partially degraded.
                EOF
              }
            },
            {
              alert = "KubeAPIHighLatency"
              expr  = <<-EOF
              histogram_quantile(0.99,
                sum by (le, verb, instance) (
                  rate(apiserver_request_duration_seconds_bucket{job="kubernetes-api-servers", verb!~"LIST|WATCH|CONNECT"}[5m])
                )
              ) > 0.4
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High API server latency"
                description = <<-EOF
                p99 latency for {{ $labels.verb }} requests on {{ $labels.instance }} is {{ $value }}s.
                EOF
              }
            },
            {
              alert = "KubeAPIServerSlowList"
              expr  = <<-EOF
              histogram_quantile(0.99,
                sum by (le, resource, instance) (
                  rate(apiserver_request_duration_seconds_bucket{job="kubernetes-api-servers", verb="LIST"}[5m])
                )
              ) > 5
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Slow LIST requests on apiserver"
                description = <<-EOF
                p99 LIST latency for {{ $labels.resource }} on {{ $labels.instance }} is {{ $value }}s.
                EOF
              }
            },
            {
              alert = "KubeAPIServerFlapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{job="kubernetes-api-servers"}[10m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "kube-apiserver is flapping"
                description = <<-EOF
                Instance {{ $labels.instance }} has restarted {{ $value }} times in 10m.
                Possible crash-loop or instability.
                EOF
              }
            },
            {
              alert = "KubeAPIServerHighCPU"
              expr  = <<-EOF
              rate(process_cpu_seconds_total{job="kubernetes-api-servers"}[5m]) > 0.75
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CPU usage on kube-apiserver"
                description = <<-EOF
                Instance {{ $labels.instance }} using {{ $value | humanize }}% CPU.
                EOF
              }
            },
          ]
        },
        {
          name = "etcd"
          rules = [
            {
              alert = "EtcdMemberDown"
              expr  = <<-EOF
              sum(up{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}) < ${length(local.members.etcd)}
              or
              absent(up{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"})
              EOF
              for   = "90s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "etcd member is down"
                description = <<-EOF
                Only {{ $value }} out of ${length(local.members.etcd)} etcd members are up.
                Nodes affected: {{ $labels.node }}
                EOF
              }
            },
            {
              alert = "EtcdNoLeader"
              expr  = <<-EOF
              sum(etcd_server_has_leader{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}) == 0
              EOF
              for   = "30s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "etcd cluster has no leader"
                description = <<-EOF
                etcd cluster has lost its leader. Cluster operations may be blocked.
                EOF
              }
            },
            {
              alert = "EtcdHighNumberOfLeaderChanges"
              expr  = <<-EOF
              increase(etcd_server_leader_changes_seen_total{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High etcd leader changes"
                description = <<-EOF
                etcd leader has changed {{ $value }} times in the last 15 minutes.
                This often indicates network issues, disk latency, or resource pressure on on-prem nodes.
                EOF
              }
            },
            {
              alert = "EtcdProposalsFailed"
              expr  = <<-EOF
              rate(etcd_server_proposals_failed_total{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}[5m]) > 0
              EOF
              for   = "3m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "etcd proposals are failing"
                description = <<-EOF
                etcd is failing to apply proposals on instance {{ $labels.instance }}.
                This can lead to cluster instability.
                EOF
              }
            },
            {
              alert = "EtcdHighCommitDuration"
              expr  = <<-EOF
              histogram_quantile(0.99,
                sum by (le, instance) (rate(etcd_disk_backend_commit_duration_seconds_bucket{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}[5m]))
              ) > 0.1
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High etcd commit duration"
                description = <<-EOF
                p99 etcd backend commit duration on {{ $labels.instance }} is {{ $value }} seconds.
                Check disk I/O (SSD recommended for etcd).
                EOF
              }
            },
            {
              alert = "EtcdDatabaseQuotaLow"
              expr  = <<-EOF
              etcd_mvcc_db_total_size_in_bytes{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"} / etcd_server_quota_backend_bytes{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"} > 0.85
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "etcd database size approaching quota"
                description = <<-EOF
                etcd DB usage on {{ $labels.instance }} is at {{ $value | humanize }}% of quota.
                Consider defragmentation or increasing quota.
                EOF
              }
            },
            {
              alert = "EtcdMemberFlapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{app="${local.endpoints.etcd.name}",namespace="${local.endpoints.etcd.namespace}"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "etcd member is restarting frequently"
                description = <<-EOF
                Instance {{ $labels.instance }} has restarted {{ $value }} times in 15 minutes.
                Possible crash-loop or OOM.
                EOF
              }
            },
          ]
        },
        {
          name = "kube-dns"
          rules = [
            {
              alert = "CoreDNSDown"
              expr  = <<-EOF
              sum(up{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}) < 2
              or
              absent(up{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"})
              EOF
              for   = "90s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "CoreDNS / kube-dns instance is down"
                description = <<-EOF
                CoreDNS pods are unreachable.
                Nodes affected: {{ $labels.node }}
                EOF
              }
            },
            {
              alert = "CoreDNSHighErrorRate"
              expr  = <<-EOF
              sum by (instance, node) (rate(coredns_dns_responses_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}",rcode=~"SERVFAIL|REFUSED"}[5m]))
              /
              sum by (instance, node) (rate(coredns_dns_requests_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m])) > 0.05
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CoreDNS error rate"
                description = <<-EOF
                CoreDNS instance on {{ $labels.node }} has >5% error responses (SERVFAIL/REFUSED/etc.).
                EOF
              }
            },
            {
              alert = "CoreDNSHighLatency"
              expr  = <<-EOF
              histogram_quantile(0.99,
                sum by (le, instance, node) (rate(coredns_dns_request_duration_seconds_bucket{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m]))
              ) > 0.2
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CoreDNS query latency"
                description = <<-EOF
                p99 DNS query latency on {{ $labels.node }} is {{ $value }} seconds.
                This can cause application timeouts.
                EOF
              }
            },
            {
              alert = "CoreDNSCacheHitRateLow"
              expr  = <<-EOF
              sum by (instance, node) (rate(coredns_proxy_conn_cache_hits_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m]))
              /
              (sum by (instance, node) (rate(coredns_proxy_conn_cache_hits_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m])) + sum by (instance) (rate(coredns_proxy_conn_cache_misses_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m])))
              < 0.7
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "CoreDNS cache hit rate low"
                description = <<-EOF
                Cache hit rate on {{ $labels.node }} is {{ $value | humanizePercentage }}.
                Consider increasing cache size or checking query patterns.
                EOF
              }
            },
            {
              alert = "CoreDNSForwardHealthcheckFailed"
              expr  = <<-EOF
              rate(coredns_forward_healthcheck_broken_total{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[5m]) > 0
              EOF
              for   = "3m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "CoreDNS forward healthcheck failing"
                description = <<-EOF
                CoreDNS is unable to reach upstream forwarders on {{ $labels.node }}.
                EOF
              }
            },
            {
              alert = "CoreDNSFlapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{app="${local.endpoints.kube_dns.name}",namespace="${local.endpoints.kube_dns.namespace}"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "CoreDNS instance flapping"
                description = <<-EOF
                Instance {{ $labels.instance }} has restarted {{ $value }} times in 15 minutes.
                Possible crash-loop or OOM.
                EOF
              }
            },
          ]
        },
        {
          name = "minio"
          rules = [
            /*
            {
              alert = "ErasureSetNearingQuorumLoss"
              expr = <<-EOF
              minio_cluster_erasure_set_write_tolerance{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} <= 1
              EOF
              for = "1m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "Erasure set {{ $labels.pool_id }}/{{ $labels.set_id }} operating at minimum capacity"
              }
            },
            {
              alert = "ErasureSetQuorumLossImminent"
              expr = <<-EOF
              minio_cluster_erasure_set_write_tolerance{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} <=
              floor(minio_cluster_erasure_set_write_quorum{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}/2)
              EOF
              for = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "Erasure set {{ $labels.pool_id }}/{{ $labels.set_id }} at 1/2 write availability"
              }
            },
            */
            {
              alert = "HighServerErrorRate"
              expr  = <<-EOF
              rate(minio_api_requests_5xx_errors_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[5m]) > 1
              EOF
              for   = "2m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "High 5xx error rate on {{ $labels.server }}: {{ $value | humanize }} errors/sec"
              }
            },
            {
              alert = "StorageCapacityDecreasing"
              expr  = <<-EOF
              deriv(minio_cluster_health_capacity_usable_free_bytes{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[1h]) / (1024 * 1024 * 1024) < -1
              EOF
              for   = "30m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Cluster storage decreasing rapidly (>1GB/hour)"
              }
            },
            {
              alert = "StorageFreeSpaceIncreasing"
              expr  = <<-EOF
              deriv(minio_cluster_health_capacity_usable_free_bytes{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[1h]) / (1024 * 1024 * 1024) > 1
              EOF
              for   = "30m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Cluster free space increasing rapidly (>1GB/hour)"
              }
            },
            {
              alert = "StorageCapacityCritical"
              expr  = <<-EOF
              (minio_cluster_health_capacity_usable_free_bytes{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} /
              minio_cluster_health_capacity_usable_total_bytes{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}) < 0.30
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Cluster storage {{ $value | humanizePercentage }} free (below 30%)"
              }
            },
            {
              alert = "GoroutineCountHigh"
              expr  = <<-EOF
              minio_system_process_go_routine_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} > 10000
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Node {{ $labels.server }} has {{ $value }} goroutines (threshold: 10000)"
              }
            },
            {
              alert = "GoroutineCountRapidlyIncreasing"
              expr  = <<-EOF
              deriv(minio_system_process_go_routine_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[5m]) > 10
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Goroutine count on {{ $labels.server }} increasing at {{ $value | humanize }}/sec"
              }
            },
            {
              alert = "HighClientErrorRate"
              expr  = <<-EOF
              rate(minio_api_requests_4xx_errors_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[5m]) > 1
              EOF
              for   = "2m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "High 4xx error rate on {{ $labels.server }}: {{ $value | humanize }} errors/sec"
              }
            },
            {
              alert = "ErasureSetDegraded"
              expr  = <<-EOF
              minio_cluster_erasure_set_health{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} == 0
              EOF
              for   = "15m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Erasure set {{ $labels.pool_id }}/{{ $labels.set_id }} is degraded"
              }
            },
            {
              alert = "DriveOffline"
              expr  = <<-EOF
              minio_system_drive_health{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} == 0
              EOF
              for   = "10m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "Drive {{ $labels.drive }} at index {{ $labels.drive_index }} in server {{$labels.server}} is offline."
              }
            },
            {
              alert = "MemoryUsageHigh"
              expr  = <<-EOF
              minio_system_memory_used_perc{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} > 90
              EOF
              for   = "10m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "Memory usage on {{ $labels.server }} at {{ $value }}%"
              }
            },
            {
              alert = "MemoryUsageIncreasing"
              expr  = <<-EOF
              deriv(minio_system_memory_used_perc{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}[15m]) > 1.25 and
              minio_system_memory_used_perc{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} > 50
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Memory usage on {{ $labels.server }} increasing rapidly ({{ $value }}%/15min)"
              }
            },
            {
              alert = "ScannerStalled"
              expr  = <<-EOF
              minio_scanner_last_activity_seconds{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} > 172800
              EOF
              for   = "2m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Scanner inactive on {{ $labels.server }} for {{ $value | humanizeDuration }}"
              }
            },
            {
              alert = "FileDescriptorExhaustion"
              expr  = <<-EOF
              (minio_system_process_file_descriptor_open_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"} /
              minio_system_process_file_descriptor_limit_total{app="${local.endpoints.minio.name}",namespace="${local.endpoints.minio.namespace}"}) > 0.90
              EOF
              for   = "2m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "MinIO process on {{ $labels.server }} using {{ $value | printf \"%.2f\" }}% of available file descriptors"
              }
            },
          ]
        },
        {
          name = "kea"
          rules = [
            {
              alert = "KeaDHCP4Down"
              expr  = <<-EOF
              sum(up{app="${local.endpoints.kea.name}",namespace="${local.endpoints.kea.namespace}"}) < 2
              or
              absent(up{app="${local.endpoints.kea.name}",namespace="${local.endpoints.kea.namespace}"})
              EOF
              for   = "90s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Kea DHCPv4 instance is down"
                description = <<-EOF
                Kea DHCPv4 pods are unreachable.
                Nodes affected: {{ $labels.node }}
                EOF
              }
            },
            {
              alert = "KeaDHCP4PoolUsageHigh"
              expr  = <<-EOF
              max by (subnet_id) (
                kea_dhcp4_pool_addresses_assigned_total{app="${local.endpoints.kea.name}",namespace="${local.endpoints.kea.namespace}"} /
                (kea_dhcp4_pool_addresses_total{app="${local.endpoints.kea.name}",namespace="${local.endpoints.kea.namespace}"} + 1)
              ) > 0.90
              EOF
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Kea DHCPv4 pool usage high"
                description = <<-EOF
                DHCPv4 pool {{ $labels.subnet }} is at {{ $value | humanize }}% utilization.
                EOF
              }
            },
            {
              alert = "KeaDHCP4Flapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{app="${local.endpoints.kea.name}",namespace="${local.endpoints.kea.namespace}"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Kea DHCPv4 instance flapping"
                description = <<-EOF
                Instance {{ $labels.instance }} has restarted {{ $value }} times in 15 minutes.
                Possible crash-loop, OOM, or configuration reload issues.
                EOF
              }
            },
          ]
        },
        {
          name = "cri-o"
          rules = [
            {
              alert = "CRIOHighErrorRate"
              expr  = <<-EOF
              sum by (instance, operation) (rate(container_runtime_crio_operations_errors_total{job="cri-o"}[5m]))
              /
              sum by (instance, operation) (rate(container_runtime_crio_operations_total{job="cri-o"}[5m])) > 0.05
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CRI-O operation error rate"
                description = <<-EOF
                CRI-O on {{ $labels.instance }} has >5% errors for operation {{ $labels.operation }}.
                EOF
              }
            },
            {
              alert = "CRIOFlapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{job="cri-o"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "CRI-O instance flapping"
                description = <<-EOF
                CRI-O on {{ $labels.instance }} has restarted {{ $value }} times in 15 minutes.
                Possible crash-loop, OOM, or configuration issue.
                EOF
              }
            },
          ]
        },
        {
          name = "kube-proxy"
          rules = [
            {
              alert = "KubeProxyDown"
              expr  = <<-EOF
              sum(up{app="kube-proxy",namespace="kube-system"}) < sum(up{job="kubernetes-nodes"})
              or
              absent(up{app="kube-proxy",namespace="kube-system"})
              EOF
              for   = "90s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "kube-proxy is down on node"
                description = <<-EOF
                kube-proxy pods are unreachable.
                Nodes affected: {{ $labels.node }}
                EOF
              }
            },
            {
              alert = "KubeProxySyncRulesSlow"
              expr  = <<-EOF
              histogram_quantile(0.99,
                sum by (le, instance, node) (rate(kubeproxy_sync_proxy_rules_duration_seconds_bucket{app="kube-proxy",namespace="kube-system"}[5m]))
              ) > 2.0
              EOF
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Slow kube-proxy rule synchronization"
                description = <<-EOF
                p99 sync proxy rules duration on node {{ $labels.node }} is {{ $value }} seconds.
                New services or endpoint changes may be delayed.
                EOF
              }
            },
            {
              alert = "KubeProxyFlapping"
              expr  = <<-EOF
              changes(process_start_time_seconds{app="kube-proxy",namespace="kube-system"}[15m]) > 3
              EOF
              for   = "0m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "kube-proxy instance flapping"
                description = <<-EOF
                kube-proxy on {{ $labels.node }} has restarted {{ $value }} times in 15 minutes.
                Possible crash-loop or configuration reload issues.
                EOF
              }
            },
          ]
        },
      ]
    }
  }
  cluster_domain   = local.domains.kubernetes
  ingress_hostname = local.endpoints.prometheus.ingress
  gateway_ref = {
    name      = local.endpoints.traefik.name
    namespace = local.endpoints.traefik.namespace
  }
  minio_endpoint      = "${local.services.cluster_minio.ip}:${local.service_ports.minio}"
  minio_bucket        = "prometheus"
  minio_access_secret = local.minio_users.prometheus.secret
}