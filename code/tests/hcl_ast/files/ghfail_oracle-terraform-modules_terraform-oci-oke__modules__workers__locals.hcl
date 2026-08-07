# Copyright (c) 2022, 2023 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  boot_volume_size        = lookup(var.shape, "boot_volume_size", 50)
  boot_volume_vpus_per_gb = lookup(var.shape, "boot_volume_vpus_per_gb", 10)
  memory                  = lookup(var.shape, "memory", 4)
  ocpus                   = max(1, lookup(var.shape, "ocpus", 1))
  shape                   = lookup(var.shape, "shape", "VM.Standard.E4.Flex")

  # Used for default values of required input for virtual node pools
  fault_domains_all = formatlist("FD-%v", [1, 2, 3])
  fault_domains_available = {
    for ad, fd in data.oci_identity_fault_domains.all : ad => fd
  }

  worker_pool_defaults = {
    agent_config = {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config           = {}
    }
    allow_autoscaler               = false
    legacy_imds_endpoints_disabled = var.legacy_imds_endpoints_disabled
    assign_public_ip               = var.assign_public_ip
    assign_ipv6ip                  = var.enable_ipv6 ? true : false
    autoscale                      = false
    block_volume_type              = var.block_volume_type
    boot_volume_size               = local.boot_volume_size
    boot_volume_vpus_per_gb        = local.boot_volume_vpus_per_gb
    capacity_reservation_id        = var.capacity_reservation_id
    cloud_init                     = [] # empty pool-specific default
    compartment_id                 = var.compartment_id
    create                         = true
    disable_default_cloud_init     = var.disable_default_cloud_init
    drain                          = false
    eviction_grace_duration        = 300
    force_node_action              = true
    force_node_delete              = true
    extended_metadata              = {} # empty pool-specific default
    ignore_initial_pool_size       = false
    image_id                       = var.image_id
    image_type                     = var.image_type
    kubernetes_version             = var.kubernetes_version
    max_pods_per_node              = min(max(var.max_pods_per_node, 1), 110)
    memory                         = local.memory
    mode                           = var.worker_pool_mode
    node_cycling_enabled           = false
    node_cycling_max_surge         = 1
    node_cycling_max_unavailable   = 0
    node_cycling_mode              = ["instance"]
    node_labels                    = var.node_labels
    nsg_ids                        = [] # empty pool-specific default
    ocpus                          = local.ocpus
    os                             = var.image_os
    os_version                     = var.image_os_version
    placement_ads                  = var.ad_numbers
    platform_config                = var.platform_config
    pod_nsg_ids                    = var.pod_nsg_ids
    pod_subnet_id                  = coalesce(var.pod_subnet_id, var.worker_subnet_id, "none")
    preemptible_config             = var.preemptible_config
    pv_transit_encryption          = var.pv_transit_encryption
    shape                          = local.shape
    size                           = var.worker_pool_size
    subnet_id                      = var.worker_subnet_id
    taints                         = [] # empty pool-specific default
    volume_kms_key_id              = var.volume_kms_key_id
  }

  # Merge desired pool configuration onto default values
  worker_pools_with_defaults = { for pool_name, pool in var.worker_pools :
    pool_name => merge(local.worker_pool_defaults, pool)
  }

  # Filter worker_pools map for enabled entries and add derived configuration
  enabled_worker_pools = { for pool_name, pool in local.worker_pools_with_defaults :
    pool_name => merge(pool, {
      preemptible_config = lookup(pool, "preemptible_config", pool.preemptible_config)
      # Bare metal instances must use iSCSI block volume attachments, not paravirtualized
      block_volume_type = length(regexall("^BM", pool.shape)) > 0 ? "iscsi" : var.block_volume_type
      pv_transit_encryption = alltrue([
        var.pv_transit_encryption,
        pool.block_volume_type == "paravirtualized",
        length(regexall("^VM", pool.shape)) > 0
      ])

      # Combine global and pool-specific cloud init parts
      cloud_init = [for part in concat(var.cloud_init, pool.cloud_init) :
        {
          # Load content from file if local path, attempt base64 decode, or use raw value
          content = contains(keys(part), "content") ? (
            try(fileexists(lookup(part, "content")), false) ? file(lookup(part, "content"))
            : try(base64decode(lookup(part, "content")), lookup(part, "content"))
          ) : ""
          content_type = lookup(part, "content_type", local.default_cloud_init_content_type)
          filename     = lookup(part, "filename", null)
          merge_type   = lookup(part, "merge_type", local.default_cloud_init_merge_type)
        }
      ]

      agent_config = coalesce(var.agent_config, pool.agent_config, local.worker_pool_defaults.agent_config)

      # Translate configured + available AD numbers e.g. 2 into tenancy/compartment-specific names
      availability_domains = compact([for ad_number in tolist(setintersection(pool.placement_ads, var.ad_numbers)) :
        lookup(var.ad_numbers_to_names, ad_number, null)
      ])

      # Use provided image_id for 'custom' type, or first match for all shape + OS criteria
      image_id = (
        pool.image_type == "custom" ?
        pool.image_id :
        element(split("###", element(reverse(sort([for entry in tolist(setintersection([
          pool.image_type == "oke" ?
          setintersection(
            lookup(var.image_ids, "oke", null),
            lookup(var.image_ids, trimprefix(lower(pool.kubernetes_version), "v"), null)
          ) :
          lookup(var.image_ids, "platform", null),
          lookup(var.image_ids, pool.image_type, null),
          length(regexall("GPU", pool.shape)) > 0 ? var.image_ids.gpu : var.image_ids.nongpu,
          length(regexall("A[12]\\.", pool.shape)) > 0 ? var.image_ids.aarch64 : var.image_ids.x86_64,
          lookup(var.image_ids, format("%v %v", pool.os, split(".", pool.os_version)[0]), null),
        ]...)) : "${var.indexed_images[entry].sort_key}###${entry}"])), 0)), 1)
      )

      # Standard tags as defined if enabled for use
      # User-provided freeform tags are merged and take precedence
      defined_tags = merge(
        var.use_defined_tags ? merge(
          {
            "${var.tag_namespace}.state_id"           = var.state_id,
            "${var.tag_namespace}.role"               = "worker",
            "${var.tag_namespace}.pool"               = pool_name,
            "${var.tag_namespace}.cluster_autoscaler" = pool.allow_autoscaler ? "allowed" : "disabled",
          },
          pool.autoscale ? { "${var.tag_namespace}.cluster_autoscaler" = "managed" } : {},
        ) : {},
        var.defined_tags,
        lookup(pool, "defined_tags", {})
      )

      # Standard tags as freeform if defined tags are disabled
      # User-provided freeform tags are merged and take precedence
      freeform_tags = merge(
        var.use_defined_tags ? {} : merge(
          {
            "state_id"           = var.state_id,
            "role"               = "worker",
            "pool"               = pool_name,
            "cluster_autoscaler" = pool.allow_autoscaler ? "allowed" : "disabled",
          },
          pool.autoscale ? { "cluster_autoscaler" = "managed" } : {},
        ),
        var.freeform_tags,
        lookup(pool, "freeform_tags", {})
      )

      # Combine global and pool-specific NSGs
      nsg_ids      = compact(concat(var.worker_nsg_ids, pool.nsg_ids))
      pods_nsg_ids = compact(concat(var.pod_nsg_ids, pool.pod_nsg_ids))

      # Add a node label for cluster autoscaler where scheduling is supported
      node_labels = merge(
        {
          "oke.oraclecloud.com/tf.module"          = "terraform-oci-oke"
          "oke.oraclecloud.com/tf.state_id"        = var.state_id
          "oke.oraclecloud.com/pool.name"          = pool_name
          "oke.oraclecloud.com/pool.mode"          = pool.mode
          "oke.oraclecloud.com/cluster_autoscaler" = pool.allow_autoscaler ? "allowed" : "disabled"
          "oci.oraclecloud.com/vcn-native-ip-cni"  = var.cni_type == "npn" ? true : false
        },
        pool.autoscale ? { "oke.oraclecloud.com/cluster_autoscaler" = "managed" } : {},
        pool.node_labels,
      )

      # Override Node-cycling mode
      node_cycling_mode = pool.node_cycling_mode != null ? [for entry in pool.node_cycling_mode : lookup(local.supported_node_cycling_mode, lower(entry))] : null

    }) if tobool(pool.create)
  }

  supported_node_cycling_mode = {
    instance    = "INSTANCE_REPLACE"
    boot_volume = "BOOT_VOLUME_REPLACE"
  }

  enabled_modes = distinct([for w in values(local.enabled_worker_pools) : w.mode])

  # Number of nodes expected from enabled worker pools
  expected_node_count = length(local.enabled_worker_pools) == 0 ? 0 : sum([
    for k, v in local.enabled_worker_pools : lookup(v, "size", var.worker_pool_size)
  ])

  # Number of nodes expected to be draining in worker pools
  expected_drain_count = length(local.enabled_worker_pools) == 0 ? 0 : sum([
    for k, v in local.enabled_worker_pools : tobool(v.drain) ? lookup(v, "size", var.worker_pool_size) : 0
  ])

  # Number of work pools in the worker pools with autoscale enabled
  expected_autoscale_worker_pools = length(local.enabled_worker_pools) == 0 ? 0 : sum([
    for k, v in local.enabled_worker_pools : tobool(v.autoscale) ? 1 : 0
  ])

  # Enabled worker_pool map entries for node pools
  enabled_node_pools = {
    for k, v in local.enabled_worker_pools : k => v
    if lookup(v, "mode", "") == "node-pool"
  }

  # Enabled worker_pool map entries for virtual node pools
  enabled_virtual_node_pools = {
    for k, v in local.enabled_worker_pools : k => v
    if lookup(v, "mode", "") == "virtual-node-pool"
  }

  # Enabled worker_pool map entries for instance pools
  enabled_instance_configs = {
    for k, v in local.enabled_worker_pools : k => v
    if contains(["cluster-network", "instance-pool"], lookup(v, "mode", ""))
  }

  # Enabled worker_pool map entries for instance pools
  enabled_instance_pools = {
    for k, v in local.enabled_worker_pools : k => v if lookup(v, "mode", "") == "instance-pool"
  }

  # Enabled worker_pool map entries for individual instances
  enabled_instances = { for e in concat([], [
    for k, v in local.enabled_worker_pools : [
      for i in range(0, lookup(v, "size", 0)) : merge(v, { "key" = k, "index" = i })
    ] if lookup(v, "mode", "") == "instance"
  ]...) : format("%v-%v", lookup(e, "key"), lookup(e, "index")) => e }

  # Enabled worker_pool map entries for cluster networks
  enabled_cluster_networks = {
    for k, v in local.enabled_worker_pools : k => v if lookup(v, "mode", "") == "cluster-network"
  }

  # Enabled worker_pool map entries for compute clusters
  enabled_compute_clusters = {
    for k, v in local.enabled_worker_pools : k => v if lookup(v, "mode", "") == "compute-cluster"
  }

  # Prepare a map workers node enabled for compute_clusters { "pool_id###worker_id" => pool_values }
  compute_cluster_instance_ids_map = { for k, v in local.enabled_compute_clusters : k => toset(lookup(v, "instance_ids", [])) }
  compute_cluster_instance_ids     = toset(concat(flatten([for k, v in local.compute_cluster_instance_ids_map : [for id in v : format("%s###%s", k, id)]])))
  compute_cluster_instance_map     = { for id in local.compute_cluster_instance_ids : id => lookup(local.enabled_compute_clusters, element(split("###", id), 0), {}) }

  # Sanitized worker_pools output; some conditionally-used defaults would be misleading
  worker_pools_final = {
    for pool_name, pool in local.enabled_worker_pools : pool_name => { for a, b in pool : a => b
      if a != "create"                                                                    # implied
      && b != null && try(length(b), -1) != 0 && try(!!tobool(b), true)                   # exclude empty/disabled values
      && !(contains(["os", "os_version"], a) && pool.image_type == "custom")              # unused defaults for custom
      && !(contains(["pod_nsg_ids", "pod_subnet_id"], a) && var.cni_type != "npn")        # unused defaults for NPN
      && !(contains(["ocpus", "memory"], a) && length(regexall("Flex", pool.shape)) == 0) # unused defaults for non-Flex shapes
    }
  }

  # Maps of worker pool OCI resources by pool name enriched with desired/custom parameters for various modes
  worker_node_pools         = { for k, v in merge(oci_containerengine_node_pool.tfscaled_workers, oci_containerengine_node_pool.autoscaled_workers) : k => merge(lookup(local.worker_pools_final, k, {}), v) }
  worker_virtual_node_pools = { for k, v in oci_containerengine_virtual_node_pool.workers : k => merge(lookup(local.worker_pools_final, k, {}), v) }
  worker_instance_pools     = { for k, v in merge(oci_core_instance_pool.tfscaled_workers, oci_core_instance_pool.autoscaled_workers) : k => merge(lookup(local.worker_pools_final, k, {}), v) }
  worker_cluster_networks   = { for k, v in oci_core_cluster_network.workers : k => merge(lookup(local.worker_pools_final, k, {}), v) }
  worker_instances          = { for k, v in oci_core_instance.workers : k => merge(lookup(local.worker_pools_final, k, {}), v) }

  # Combined map of outputs by pool name for all modes excluding 'instance' (output separately)
  worker_pools_output = merge(
    local.worker_node_pools,
    local.worker_virtual_node_pools,
    local.worker_instance_pools,
    local.worker_cluster_networks,
  )

  # OCIDs of pool resources by pool name for modes: 'node-pool', 'virtual-node-pool', 'instance-pool', 'cluster-network'
  worker_pool_ids = { for k, v in local.worker_pools_output : k => v.id }

  # Map of pool name to list of instance IP addresses for modes: 'instance'
  worker_instance_ips = {
    for x, y in {
      for k, v in local.worker_instances : replace(k, "/-[^-]*$/", "") => # remove index suffix
      { lookup(v, "id", "") = lookup(v, "private_ip", null) }...          # instances grouped by "pool"
    } : x => merge(y...)
  }

  # Map of pool name to list of instance IP addresses for modes: 'node-pool'
  worker_nodepool_ips = {
    for k, v in local.worker_node_pools : k => {
      for n in lookup(v, "nodes", []) : lookup(n, "id", "") => lookup(n, "private_ip", null)
    }
  }

  # Yields {<pool name> = {<instance id> = <instance ip>}} for modes: 'node-pool', 'instance'
  worker_pool_ips = merge(local.worker_instance_ips, local.worker_nodepool_ips)

  # Map of nodepools using Ubuntu images.

  ubuntu_supported_versions = {
    "22.04"                 = "jammy"
    "24.04"                 = "noble"
    "22.04 Minimal"         = "jammy"
    "22.04 Minimal aarch64" = "jammy"
    "24.04 Minimal"         = "noble"
    "24.04 Minimal aarch64" = "noble"
  }

  ubuntu_worker_pools = {
    for k, v in local.enabled_worker_pools : k => {
      kubernetes_major_version = substr(lookup(v, "kubernetes_version", ""), 1, 4)
      kubernetes_minor_version = substr(lookup(v, "kubernetes_version", ""), 1, -1)
      ubuntu_release           = lookup(lookup(data.oci_core_image.workers, k, {}), "operating_system_version", null) != null ? lookup(lookup(data.oci_core_image.workers, k, {}), "operating_system_version") : lookup(v, "os_version", null)
    }
    if lookup(v, "mode", var.worker_pool_mode) != "virtual-node-pool" &&
    contains(coalescelist(split(" ", lookup(lookup(data.oci_core_image.workers, k, {}), "operating_system", "")), [lookup(v, "os", "")]), "Ubuntu")
  }
}
