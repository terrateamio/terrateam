resource "null_resource" "link_init" {
  connection {
    type     = "ssh"
    host     = var.prov_remote.host
    port     = var.prov_remote.port
    user     = var.prov_remote.user
    password = var.prov_remote.password
  }
  # triggers = {
  #   TARGET_DIR = "/var/home/core/.local/etc/containers/systemd"
  #   LINK_DIR   = "/etc/containers/systemd"
  # }
  provisioner "remote-exec" {
    inline = [
      templatefile("${path.root}/attachments/init.sh", {
        DATA_DIR   = "/mnt/data/nfs"
        TARGET_DIR = "/var/home/core/.local/etc/containers/systemd"
        LINK_PATH  = "/etc/containers/systemd/1000"
      })
    ]
  }
}

module "podman_quadlet" {
  depends_on = [
    null_resource.link_init,

  ]
  source  = "../../modules/system-systemd_quadlet-root"
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
        # custom_trigger = md5(remote_file.podman_kubes[unit.service.name].content)
      }
    ]
  }
}
