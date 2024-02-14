us_clusters_filters = flatten([
  for cluster in local.us_clusters : [
    for pool_filter in local.us_lqs_pod_pool_filters : {
      cluster = cluster
      pool_filter = pool_filter
    }
  ]
])
