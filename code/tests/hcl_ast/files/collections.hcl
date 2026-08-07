foo1 = [1]
foo2 = [1, 2, 3]
foo3 = [ 1,
  2
  ,
  3,
  4,
]
foo4 = [for s in var.list: upper(s)]
foo5 = [for k, v in var.map : length(k) + length(v)]
foo6 = {for s in var.list : s => upper(s)}
foo7 = [for s in var.list : upper(s) if s != ""]
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
