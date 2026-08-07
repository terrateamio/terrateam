# Copyright IBM Corp. 2022, 2023
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
  }
}

resource "local_file" "output_main_file" {
  content = templatefile("${path.module}/template.tftpl", {
    pairs = local.pairs
  })
  filename = "${var.generated_module_dir}/main.tf"
}

resource "local_file" "output_provider_file" {
  content  = file("${var.provider_file}")
  filename = "${var.generated_module_dir}/${basename(var.provider_file)}"
}

locals {
  # We will use this to do lexicographical comparisons by fetching indexes.
  # It is necessary to establish asymmetry so that the cross product doesn't
  # produce (x,y) and (y,x) pairs.
  order = distinct(concat(
    sort([for p in var.peering_acceptors : "${p.alias}+${p.partition}"]),
    sort([for p in var.peering_dialers : "${p.alias}+${p.partition}"]),
  ))

  unclean_pairs = flatten([
    for a in var.peering_acceptors : [
      for d in var.peering_dialers :
      # Skip pairs of the same cluster
      a.alias == d.alias ||
      # Skip the second instance if we see the same pair twice.
      (
        contains(var.peering_acceptors, { alias : d.alias, partition : d.partition })
        && contains(var.peering_dialers, { alias : a.alias, partition : a.partition })
        && index(local.order, "${a.alias}+${a.partition}") > index(local.order, "${d.alias}+${d.partition}")
      )
      ? {}
      : {
        acceptor : a.alias,
        acceptor_partition : a.partition,
        acceptor_name : a.partition == "" ? a.alias : "${a.alias}-${a.partition}",
        dialer : d.alias,
        dialer_partition : d.partition,
        dialer_name : d.partition == "" ? d.alias : "${d.alias}-${d.partition}",
      }
    ]
  ])
  # This will contain the list of all clusters that should be contacting eachother.
  # A cluster cannot peer to itself.
  cluster_pairs = setsubtract(distinct(local.unclean_pairs), [{}])

  # We could stop here if partitions didn't exist.
  pairs = local.cluster_pairs
}

