# Per the HCL2 spec, an object key wrapped in parentheses is a "computed
# key": the parenthesized expression is evaluated and its result is used as
# the key. Without the parens, a bare identifier is taken as a literal name.
# (See https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md#collection-values.)
# each Terraform-style binding prefix (var, local, module, data, ...) plus a
# few related shapes (single bare identifier, deeper traversal, indexed).

a = { (var.foo) = "v" }
a_read = { v = var.foo }

b = { (local.foo) = "v" }
b_read = { v = local.foo }

c = { (module.foo) = "v" }
c_read = { v = module.foo }

d = { (data.foo) = "v" }
d_read = { v = data.foo }

e = { (path.foo) = "v" }
e_read = { v = path.foo }

f = { (terraform.foo) = "v" }
f_read = { v = terraform.foo }

g = { (var) = "v" }
g_read = { v = var }

h = { (foo) = "v" }
h_read = { v = foo }

i = { (var.a.b) = "v" }
i_read = { v = var.a.b }

j = { (var.a[0]) = "v" }
j_read = { v = var.a[0] }

k = { (var.a[0].b) = "v" }
k_read = { v = var.a[0].b }

l = { k1 = 1, (var.foo) = 2, k2 = 3 }
l_read = { k1 = 1, k2 = var.foo }

m = { "k" = 1, "2" = 2}

n = { "var.a.b" = 1 }

o = { "var.a[0]" = 1 }