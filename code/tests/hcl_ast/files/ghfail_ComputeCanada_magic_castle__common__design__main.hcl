data "http" "agent_ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  domain_name = "${lower(var.cluster_name)}.${lower(var.domain)}"

  min_disk_size_per_tags = {
    "mgmt" : 20
  }

  instances = merge(
    flatten([
      for prefix, attrs in var.instances : [
        for i in range(lookup(attrs, "count", 1)) : {
          (format("%s%d", prefix, i + 1)) = merge(
            { image = var.image },
            { disk_size = max(var.min_disk_size, [for tag in attrs.tags : lookup(local.min_disk_size_per_tags, tag, 0)]...) },
            { for attr, value in attrs : attr => value if !contains(["count"], attr) },
            {
              prefix = prefix,
              specs  = { for attr, value in attrs : attr => value if !contains(["count", "tags", "image"], attr) }
            },
          )
        }
      ]
    ])...
  )

  instances_to_build = {
    for key, values in local.instances : key => values
    if !contains(values.tags, "pool") || contains(var.pool, key)
  }

  instance_per_volume = merge([
    for ki, vi in var.volumes : {
      for kj, vj in vi :
      "${ki}-${kj}" => merge({
        instances = [for x, values in local.instances_to_build : x if contains(values.tags, ki)]
      }, vj)
    }
  ]...)

  volumes = merge([
    for key, values in local.instance_per_volume : {
      for instance in values["instances"] :
      "${instance}-${key}" => merge(
        { for key, value in values : key => value if key != "instances" },
      { instance = instance })
    }
  ]...)

  volume_per_instance = transpose({ for key, value in local.instance_per_volume : key => value["instances"] })

  # We look for firewall rules that allow SSH connection from the Terraform agent's ip
  # and we memorize the corresponding tags so we can determine which instances can be used as a
  # first hop when transferring files or executing remote commands with Terraform.
  agent_ip = chomp(data.http.agent_ip.response_body)
  bastion_tags = distinct(concat(var.bastion_tags, [
    for rule, values in var.firewall_rules :
    values.tag
    if values.ethertype == "IPv4" &&
    22 <= values.from_port && values.to_port <= 22 &&
    alltrue([
      for i, v in split(".", local.agent_ip) :
      tonumber(split(".", strcontains(values.cidr, "/") ? cidrhost(values.cidr, 0) : values.cidr)[i]) <= tonumber(v) &&
      tonumber(split(".", strcontains(values.cidr, "/") ? cidrhost(values.cidr, -1) : values.cidr)[i]) >= tonumber(v)
    ])
  ]))
}

check "disk_space_per_tag" {
  assert {
    condition     = alltrue(flatten([for inst in local.instances : [for tag in inst.tags : lookup(local.min_disk_size_per_tags, tag, var.min_disk_size) <= inst.disk_size]]))
    error_message = "At least one instance's disk_size is smaller than what is recommended given its set of tags.\nMininum disk size per tags: ${jsonencode(local.min_disk_size_per_tags)}"
  }
  assert {
    condition     = alltrue([for inst in local.instances : var.min_disk_size <= inst.disk_size])
    error_message = "At least one instance's disk_size is smaller than what is recommended by the cloud provider.\nMinimum disk size for provider: ${var.min_disk_size}"
  }
}
