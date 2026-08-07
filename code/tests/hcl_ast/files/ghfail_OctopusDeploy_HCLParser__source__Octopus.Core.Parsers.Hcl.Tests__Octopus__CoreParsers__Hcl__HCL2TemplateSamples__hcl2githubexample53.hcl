# Provisioning a VM by cloning on a vSphere 6.7 infrastructure
# 16.02.2020 - 15:14 - CRC

// PROVIDER declaration and connection parameters.
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  # if you have a self-signed certificate
  allow_unverified_ssl = true
}

// Data source that gathers the info for the datacenter.
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

// Populates the datastore source from this datacenter with info.
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Populates with data the cluster object from this datacenter.
data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Get data about the network for the new VM in this datacenter.
data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Get info for the template used to clone the VM.
data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Get info for the resource pool in which will be created the VM.
data "vsphere_resource_pool" "pool" {
  name          = var.res_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [
    vsphere_resource_pool.resource_pool
  ]
}

// RESOURCE declaration

// Creates the resource pool in which the VM will be created.
resource "vsphere_resource_pool" "resource_pool" {
  name                    = var.res_pool_name
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
}

// Creates the VM.
resource "vsphere_virtual_machine" "vm" {
  name             = var.vsphere_vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.vm_num_cpus
  memory   = var.vm_memory
  guest_id = data.vsphere_virtual_machine.template.guest_id
  # this enable the firmware EFI (default bios)
  firmware = "efi"
  # this enable the secure boot IF firmware is set to EFI
  efi_secure_boot_enabled = true

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  # Adds a cdrom to the new VM
  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_host_name
        domain    = var.vm_domain_name
      }

      network_interface {
        ipv4_address = var.vm_ipv4_address
        ipv4_netmask = var.vm_ipv4_netmask
      }

      ipv4_gateway = var.vm_ipv4_gateway
      # this will to allow to specify multiple values for dns servers
      dns_server_list = var.vm_dns_servers
      dns_suffix_list = var.vm_dns_search_domain
    }
  }
}