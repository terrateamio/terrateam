# load secret from vault kvv2 or load cert from tfstate
locals {
  secrets_vault_kvv2 = flatten([
    for podman_kube in var.podman_kubes : [
      for value_refer in podman_kube.helm.value_refers == null ? [] : podman_kube.helm.value_refers : {
        mount = value_refer.vault_kvv2.mount
        name  = value_refer.vault_kvv2.name
      }
      if value_refer.vault_kvv2 != null
    ]
  ])
  tls_tfstate = flatten([
    for podman_kube in var.podman_kubes : [
      for value_refer in podman_kube.helm.value_refers == null ? [] : podman_kube.helm.value_refers : {
        backend = value_refer.tfstate.backend
        name    = value_refer.tfstate.cert_name
      }
      if value_refer.tfstate != null
    ]
  ])
}

# load secret from vault
data "vault_kv_secret_v2" "secret" {
  for_each = local.secrets_vault_kvv2 == null ? null : {
    for secret_vault_kvv2 in local.secrets_vault_kvv2 : secret_vault_kvv2.name => secret_vault_kvv2
  }
  mount = each.value.mount
  name  = each.value.name
}

# load cert from terraform state
data "terraform_remote_state" "tfstate" {
  # count   = var.podman_kube.helm.value_refers.tfstate == null ? 0 : 1
  for_each = local.tls_tfstate == null ? null : {
    for tls_tfstate in local.tls_tfstate : tls_tfstate.name => tls_tfstate
  }
  backend = each.value.backend.type
  config  = each.value.backend.config
}

locals {
  cert_list = data.terraform_remote_state.tfstate == null ? null : flatten([
    for podman_kube in var.podman_kubes : [
      for value_refer in podman_kube.helm.value_refers == null ? [] : podman_kube.helm.value_refers : [
        for cert in data.terraform_remote_state.tfstate[value_refer.tfstate.cert_name].outputs.signed_certs : cert
        if cert.name == value_refer.tfstate.cert_name
      ]
      if value_refer.tfstate != null
    ]
  ])
  certs = data.terraform_remote_state.tfstate == null ? null : {
    for cert in local.cert_list : cert.name => cert
  }
}

data "helm_template" "podman_kubes" {
  for_each = {
    for podman_kube in var.podman_kubes : podman_kube.helm.name => podman_kube
  }
  name  = each.value.helm.name
  chart = each.value.helm.chart

  values = [
    "${file(each.value.helm.value_file)}"
  ]

  # v3 helm provider
  set = flatten([
    each.value.helm.value_sets == null ? [] : [
      for value_set in flatten([each.value.helm.value_sets]) : {
        name = value_set.name
        value = value_set.value_string != null ? value_set.value_string : templatefile(
          "${value_set.value_template_path}", "${value_set.value_template_vars}"
        )
      }
    ]
  ])

  set_sensitive = flatten([
    each.value.helm.value_refers == null ? [] : [
      for value_refer in each.value.helm.value_refers : [
        for value_set in value_refer.value_sets : {
          name = value_set.name
          # value = value_refer.tfstate == null ? null : local.certs[value_refer.tfstate.cert_name][value_set.value_ref_key]
          value = value_refer.tfstate == null ? data.vault_kv_secret_v2.secret[value_refer.vault_kvv2.name].data[value_set.value_ref_key] : local.certs[value_refer.tfstate.cert_name][value_set.value_ref_key]
        }
      ]
    ]
  ])
}

resource "remote_file" "podman_kubes" {
  for_each = {
    for podman_kube in var.podman_kubes : podman_kube.helm.name => podman_kube
  }
  path    = each.value.manifest_dest_path
  content = data.helm_template.podman_kubes[each.key].manifest
}

module "podman_quadlet" {
  depends_on = [
    remote_file.podman_kubes,
  ]
  source  = "../../modules/system-systemd_quadlet"
  vm_conn = var.prov_remote
  podman_quadlet = {
    files = flatten([
      for unit in var.podman_quadlet.units : [
        for file in unit.files :
        {
          content = templatefile(
            file.template,
            file.vars
          )
          path = join("/", [
            var.podman_quadlet.dir,
            join(".", [
              unit.service.name,
              split(".", basename(file.template))[1]
            ])
          ])
        }
      ]
    ])
    services = [
      for unit in var.podman_quadlet.units : unit.service == null ? null :
      {
        name           = unit.service.name
        status         = unit.service.status
        custom_trigger = md5(remote_file.podman_kubes[unit.service.name].content)
      }
    ]
  }
}

# resource "remote_file" "traefik_file_provider" {
#   for_each = toset([
#     "./attachments/minio.traefik.yaml"
#   ])
#   path    = "/var/home/podmgr/traefik-file-provider/${basename(each.key)}"
#   content = file("${each.key}")
# }

resource "remote_file" "consul_service" {
  for_each = toset([
    "./attachments/minio.consul.hcl",
  ])
  path    = "/var/home/podmgr/consul-services/${basename(each.key)}"
  content = file("${each.key}")
}
