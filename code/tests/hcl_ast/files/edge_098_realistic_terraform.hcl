locals {
  instance_tags = {
    for idx, name in var.instance_names :
    name => merge(
      var.default_tags,
      {
        Name  = name
        Index = idx
      }
    )
  }

  enabled_instances = [
    for name, tags in local.instance_tags :
    {
      name = name
      tags = tags
    }
    if lookup(tags, "enabled", true)
  ]

  instance_count = length(local.enabled_instances)
  has_instances  = local.instance_count > 0
}
