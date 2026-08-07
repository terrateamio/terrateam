locals {
  llama_cpp_port  = 8080
  models_path     = "/models"
  llama_swap_path = "/llama-swap"
  config_file     = "/var/lib/llama-cpp/config.yaml"
  models = [
    for k, image in var.models :
    {
      key   = k
      image = image.image
      file  = image.file
    }
  ]

  manifests = [
    module.statefulset.manifest,
    module.service.manifest,
    module.httproute.manifest,
    module.secret.manifest,
  ]
}

module "secret" {
  source  = "../../../modules/secret"
  name    = var.name
  app     = var.name
  release = var.release
  data = merge({
    basename(local.config_file) = yamlencode(merge(var.llama_swap_config, {
      macros = merge({
        model_path  = local.models_path
        default_cmd = <<-EOF
          /app/llama-server \
          --port $${PORT} \
          --flash-attn on \
          --no-webui \
          --context-shift \
          --no-mmap
        EOF
        }, {
        for _, v in local.models :
        "${v.key}" => "${local.models_path}/${v.key}/${v.file}"
      })
      apiKeys = [
        for i, k in var.api_keys :
        "$${env.API_KEY_${i}}"
      ]
    }))
    }, {
    for i, k in var.api_keys :
    "API_KEY_${i}" => k
  })
}

module "service" {
  source  = "../../../modules/service"
  name    = var.name
  app     = var.name
  release = var.release
  spec = {
    type = "ClusterIP"
    ports = [
      {
        name       = var.name
        port       = local.llama_cpp_port
        protocol   = "TCP"
        targetPort = local.llama_cpp_port
      },
    ]
  }
}

module "httproute" {
  source  = "../../../modules/httproute"
  name    = var.name
  app     = var.name
  release = var.release
  spec = {
    parentRefs = [
      merge({
        kind = "Gateway"
      }, var.gateway_ref),
    ]
    hostnames = [
      var.ingress_hostname,
    ]
    rules = [
      {
        matches = [
          {
            path = {
              type  = "PathPrefix"
              value = "/"
            }
          },
        ]
        backendRefs = [
          {
            name = module.service.name
            port = local.llama_cpp_port
          },
        ]
      },
    ]
  }
}

module "statefulset" {
  source = "../../../modules/statefulset"

  name     = var.name
  app      = var.name
  release  = var.release
  affinity = var.affinity
  replicas = 1
  annotations = {
    "checksum/secret" = sha256(module.secret.manifest)
  }
  template_spec = {
    resources = {
      requests = {
        memory = "8Gi"
      }
      limits = {
        memory = "96Gi" # GTT
      }
    }
    containers = [
      {
        name  = var.name
        image = var.images.llama_swap
        command = [
          "/app/llama-swap",
          "--config",
          "${local.config_file}",
          "--listen",
          "0.0.0.0:${local.llama_cpp_port}",
        ]
        volumeMounts = concat([
          {
            name      = "config"
            mountPath = local.config_file
            subPath   = basename(local.config_file)
          },
          {
            name      = "ca-trust-bundle"
            mountPath = "/etc/ssl/certs/ca-certificates.crt"
            readOnly  = true
          },
          ], [
          for _, v in local.models :
          {
            name      = v.key
            mountPath = "${local.models_path}/${v.key}"
          }
        ])
        env = concat([
          for _, e in var.extra_envs :
          {
            name  = e.name
            value = tostring(e.value)
          }
          ], [
          for i, _ in var.api_keys :
          {
            name = "API_KEY_${i}"
            valueFrom = {
              secretKeyRef = {
                name = module.secret.name
                key  = "API_KEY_${i}"
              }
            }
          }
        ])
        resources = {
          requests = {
            "amd.com/gpu" = 1
          }
          limits = {
            "amd.com/gpu" = 1
          }
        }
        ports = [
          {
            containerPort = local.llama_cpp_port
          },
        ]
        livenessProbe = {
          httpGet = {
            port = local.llama_cpp_port
            path = "/health"
          }
          initialDelaySeconds = 10
          timeoutSeconds      = 2
        }
        readinessProbe = {
          httpGet = {
            port = local.llama_cpp_port
            path = "/health"
          }
        }
      },
    ]
    volumes = concat([
      {
        name = "config"
        secret = {
          secretName = module.secret.name
        }
      },
      {
        name = "ca-trust-bundle"
        hostPath = {
          path = "/etc/ssl/certs/ca-certificates.crt"
          type = "File"
        }
      },
      ], [
      for _, v in local.models :
      {
        name = v.key
        image = {
          reference = v.image
        }
      }
    ])
  }
}