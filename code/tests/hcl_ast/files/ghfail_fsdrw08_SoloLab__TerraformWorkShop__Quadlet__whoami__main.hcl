module "podman_quadlet" {
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
        name   = unit.service.name
        status = unit.service.status
      }
    ]
  }
}

resource "remote_file" "consul_service" {
  path    = "/var/home/podmgr/consul-services/service-whoami.hcl"
  content = file("./attachments/whoami.consul.hcl")
}
