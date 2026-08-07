locals {
  simple   = var.a
  computed = var.enabled ? "yes" : "no"
  list = [
    1,
    "two",
    true,
    null,
  ]
  map = {
    a = 1
    b = "two"
  }
  access   = var.config.servers[0].hostname
  splat    = var.instances[*].id
  funcall  = join(",", var.list)
  tmpl     = "prefix-${var.name}-suffix"
  for_list = [for x in var.items : upper(x) if x != ""]
  for_map  = { for k, v in var.map : k => v }
  math     = (1 + 2) * 3
  logic    = true && !false
  compare  = 1 <= 2
  nested   = merge({ a = 1 }, { b = 2 })
  heredoc  = <<-EOT
    hello
    world
  EOT
}
