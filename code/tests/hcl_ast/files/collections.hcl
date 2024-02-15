foo = [1]
foo = [1, 2, 3]
foo = [ 1,
  2
  ,
  3,
  4,
]
foo = [for s in var.list: upper(s)]
foo = [for k, v in var.map : length(k) + length(v)]
foo = {for s in var.list : s => upper(s)}
foo = [for s in var.list : upper(s) if s != ""]
locals {
  admin_users = {
    for name, user in var.users : name => user
    if user.is_admin
  }
  regular_users = {
    for name, user in var.users : name => user
    if !user.is_admin
  }
}
