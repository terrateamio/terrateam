resource "macaddress" "agent" {
  count = var.agent_count
}

locals {
  default_ipconfig = "ip=dhcp,ip6=auto"
  node_ips = var.subnet != "" ? {
    for i in range(var.agent_count) : i => cidrhost(var.subnet, i)
    } : {
    for i in range(var.agent_count) : i => null
  }
  cidr_bitnum = var.subnet != "" ? split("/", var.subnet)[1] : null
  node_ipconfigs = {
    for i, address in local.node_ips :
    i => address != null
    ? format("ip=%s/%s,gw=%s", address, local.cidr_bitnum, var.network_gateway)
    : local.default_ipconfig
  }
}

resource "proxmox_vm_qemu" "agent" {
  count = var.agent_count

  target_node = var.proxmox_node
  name        = "${join("-", ["buildkite", count.index])}.${var.domain_name}"
  desc        = "Buildkite agent ${count.index}"
  os_type     = "cloud-init"
  agent       = 1

  clone = var.source_template

  pool = var.proxmox_resource_pool

  ciuser     = var.shape.user
  sshkeys    = file(var.authorized_keys_file)
  ipconfig0  = local.node_ipconfigs[count.index]
  nameserver = var.nameserver

  cores   = var.shape.cores
  sockets = var.shape.sockets
  memory  = var.shape.memory

  scsihw = "virtio-scsi-pci"
  disk {
    type    = var.shape.storage_type
    storage = var.shape.storage_id
    size    = var.shape.disk_size
  }

  dynamic "disk" {
    for_each = var.shape.extra_disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  network {
    bridge    = var.shape.network_bridge
    firewall  = true
    link_down = false
    macaddr   = upper(macaddress.agent[count.index].address)
    model     = "virtio"
    queues    = 0
    rate      = 0
    tag       = var.shape.network_tag
  }

  lifecycle {
    ignore_changes = [
      ciuser,
      cicustom,
      sshkeys,
      disk[0],
    ]
  }
}
