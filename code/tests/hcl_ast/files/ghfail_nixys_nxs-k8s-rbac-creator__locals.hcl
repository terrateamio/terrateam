locals {
  roles_list_array = [for i in var.roles_list :
    merge(
      var.default_roles_list,
      i,
    )
  ]

  roles_array = flatten([for i in local.roles_list_array : {
    name      = i.name
    namespace = i.namespace
    rules     = i.rules
    }
  ])

  cluster_roles_list = [for i in var.cluster_roles_list :
    merge(
      var.default_cluster_roles_list,
      i,
    )
  ]

  cluster_roles_array = flatten([for i in local.cluster_roles_list : {
    name  = i.name
    rules = i.rules
    }
  ])

  sa_array = flatten([for i in var.sa_list : {
    name      = i.name
    namespace = i.namespace
    }
  ])

  binding_array = [for i in var.bindings :
    merge(
      var.default_bindings,
      i,
    )
  ]

  users_array = toset(flatten([for i in local.binding_array : [for j in i.users : j]]))

  roles_binding_array = flatten([for i in local.binding_array : i.type != "role_binding" ? [] :
    [for j in i.namespaces :
      [for k in i.roles : {
        type      = i.type
        prefix    = i.prefix
        namespace = j
        sa        = i.sa
        users     = i.users
        groups    = i.groups
        role      = k
        }
      ]
    ]
  ])

  roles_binding_cluster_role_array = flatten([for i in local.binding_array : i.type != "role_binding" ? [] :
    [for j in i.namespaces :
      [for k in i.cluster_roles : {
        type         = i.type
        prefix       = i.prefix
        namespace    = j
        sa           = i.sa
        users        = i.users
        groups       = i.groups
        cluster_role = k
        }
      ]
    ]
  ])

  cluster_roles_binding_array = flatten([for i in local.binding_array : i.type != "cluster_role_binding" ? [] :
    [for k in i.cluster_roles : {
      type         = i.type
      prefix       = i.prefix
      sa           = i.sa
      users        = i.users
      groups       = i.groups
      cluster_role = k
      }
    ]
  ])

  merged_certificate_authority_data = merge(
    var.default_k8s_auth_cluster_ca_certificate,
    var.k8s_auth_cluster_ca_certificate,
  )

  certificate_authority_data = length(local.merged_certificate_authority_data.raw) > 0 ? base64encode(local.merged_certificate_authority_data.raw) : local.merged_certificate_authority_data.encoded
}
