variable "gremlin_databases" {
  type = map(object({
    name = string

    throughput = optional(number, null)

    autoscale_settings = optional(object({
      max_throughput = number
    }), null)

    graphs = optional(map(object({
      name = string

      partition_key_path    = string
      partition_key_version = optional(string, null)
      throughput            = optional(number, null)

      default_ttl            = optional(number, null)
      analytical_storage_ttl = optional(number, null)

      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      index_policy = optional(object({
        automatic      = optional(bool, true)
        indexing_mode  = string
        included_paths = list(string)
        excluded_paths = list(string)

        composite_index = optional(list(object({
          index = set(object({
            path  = string
            order = string
          }))
        })), null)

        spatial_index = optional(list(object({
          path = string
        })), null)
      }), null)

      conflict_resolution_policy = optional(object({
        mode                          = string
        conflict_resolution_path      = optional(string, null)
        conflict_resolution_procedure = optional(string, null)
      }), null)

      unique_key = optional(object({
        paths = list(string)
      }), null)
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Manages Gremlin Databases within a Cosmos DB Account.

  - `name`       - (Required) - Specifies the name of the Cosmos DB Gremlin Database. Changing this forces a new resource to be created.
  - `throughput` - (Optional) - Defaults to `null`. The throughput of the Gremlin database (RU/s). Must be set in increments of `100`. The minimum value is `400`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.

  - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `max_throughput` - (Required) - The maximum throughput of the Gremlin database (RU/s). Must be between `1,000` and `1,000,000`. Must be set in increments of `1,000`. Conflicts with `throughput`.

  - `graphs` - (Optional) - Defaults to `{}`. Manages a Gremlin Graph within a Cosmos DB Account.
    - `name`      - (Required) Specifies the name of the Cosmos DB Gremlin Graph. Changing this forces a new resource to be created.
    - `partition_key_path` - (Required) - The path to use for partitioning data within the Gremlin graph (e.g., `/myPartitionKey`).
    - `partition_key_version` - (Optional) - Defaults to `null`. The version of the partition key definition. Possible values are `1` or `2`.
    - `throughput` - (Optional) - Defaults to `null`. The throughput of the Gremlin graph (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon graph creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `default_ttl` - (Optional) - Defaults to `null`. The default Time To Live in seconds. If the value is -1, items are not automatically expired.
    - `analytical_storage_ttl` - (Optional) - Defaults to `null`. The time to live of Analytical Storage for this Cosmos DB Gremlin Graph. Possible values are between -1 to 2147483647 not including 0. If present and the value is set to -1, it means never expire.
    - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon graph creation otherwise it cannot be updated without a manual terraform destroy-apply.
      - `max_throughput` - (Required) - The maximum throughput of the Gremlin graph (RU/s). Must be between 1,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with `throughput`.
    - `index_policy` - (Optional) - Defaults to `null`. The indexing policy configuration for the Gremlin graph.
      - `automatic` - (Optional) - Defaults to `true`. Whether automatic indexing is enabled.
      - `indexing_mode` - (Required) - The indexing mode. Possible values are `consistent`, `lazy`, or `none`.
      - `included_paths` - (Required) - List of paths to include in the index. Note: The root path "/" must be included in either included_paths or excluded_paths.
      - `excluded_paths` - (Required) - List of paths to exclude from the index.
      - `composite_index` - (Optional) - Defaults to `null`. List of composite index definitions.
        - `index` - (Required) - Set of objects specifying `path` and `order` for each composite index (`Ascending` or `Descending`).
      - `spatial_index` - (Optional) - Defaults to `null`. List of spatial index definitions.
        - `path` - (Required) - The path for the spatial index.
    - `conflict_resolution_policy` - (Optional) - Defaults to `null`. The conflict resolution policy for the Gremlin graph.
      - `mode` - (Required) - The conflict resolution mode. Possible values are `LastWriterWins` or `Custom`.
      - `conflict_resolution_path` - (Optional) - Defaults to `null`. The path to be used for conflict resolution (required for `LastWriterWins`).
      - `conflict_resolution_procedure` - (Optional) - Defaults to `null`. The stored procedure to be used for conflict resolution (required for `Custom`).
    - `unique_key` - (Optional) - Defaults to `null`. The unique key policy for the Gremlin graph.
      - `paths` - (Required) - List of paths to enforce uniqueness on.

  Example inputs:
  ```hcl
  gremlin_databases = {
    "database_name" = {
      name = "database_gremlin"
      throughput = 400

      graphs = {
        "graph" = {
          name = "graph"
          partition_key_path = "/myPartitionKey"
          partition_key_version = "1"
          throughput = 400
          default_ttl = 3600
          analytical_storage_ttl = -1
          autoscale_settings = {
            max_throughput = 1000
        }
      }
    }
  }
  ```
  DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue(
      [
        for db in var.gremlin_databases : can(regex("^[^/\\.\"$*<>:|?]*$", db.name))
    ])
    error_message = "The name field cannot contain the characters /\\.\"$*<>:|?"
  }
  validation {
    condition = alltrue(
      [
        for db in var.gremlin_databases : length(db.name) <= 64
      ]
    )
    error_message = "The 'name' field must be 64 characters or less."
  }
  validation {
    condition = length(
      [
        for db_key, db_params in var.gremlin_databases : db_params.name
        ]) == length(distinct(
        [
          for db_key, db_params in var.gremlin_databases : db_params.name
      ])
    )
    error_message = "The 'name' in the gremlin database value must be unique."
  }
  validation {
    condition = alltrue(
      [for key, value in var.gremlin_databases : value.throughput != null ? value.throughput >= 400 : true]
    )
    error_message = "The 'throughput' in the database value must be greater than or equal to 400 if specified."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.gremlin_databases :
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput >= 1000 && value.autoscale_settings.max_throughput <= 1000000 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be between 1000 and 1000000 if specified."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.gremlin_databases :
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput % 1000 == 0 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be a multiple of 1000 if specified."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.gremlin_databases :
        try(value.autoscale_settings.max_throughput, null) != null && value.throughput != null ? false : true
      ]
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at database level."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.gremlin_databases :
        value.throughput != null ? value.throughput % 100 == 0 : true
      ]
    )
    error_message = "The 'throughput' value must be set in increments of 100 if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          length(graph_params.name) <= 255
        ]
      ])
    )
    error_message = "The graph name must not exceed 255 characters."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          can(regex("^[^/\\.\"$*<>:|?]*$", graph_params.name))
        ]
      ])
    )
    error_message = "The graph name cannot contain the characters /\\.\"$*<>:|?"
  }
  validation {
    condition = alltrue(
      [
        for db_key, db_value in var.gremlin_databases :
        length([
          for graph_key, graph_params in db_value.graphs : graph_params.name
          ]) == length(distinct([
            for graph_key, graph_params in db_value.graphs : graph_params.name
        ]))
      ]
    )
    error_message = "Graph names must be unique within each database."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.throughput != null ? graph_params.throughput >= 400 : true
        ]
      ])
    )
    error_message = "The 'throughput' value at the graph level must be greater than or equal to 400 if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.throughput != null ? graph_params.throughput % 100 == 0 : true
        ]
      ])
    )
    error_message = "The 'throughput' value at the graph level must be set in increments of 100 if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.autoscale_settings.max_throughput, null) != null ? graph_params.autoscale_settings.max_throughput >= 1000 && graph_params.autoscale_settings.max_throughput <= 1000000 : true
        ]
      ])
    )
    error_message = "The 'max_throughput' in the graph autoscale_settings value must be between 1000 and 1000000 if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.autoscale_settings.max_throughput, null) != null ? graph_params.autoscale_settings.max_throughput % 1000 == 0 : true
        ]
      ])
    )
    error_message = "The 'max_throughput' in the graph autoscale_settings value must be a multiple of 1000 if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.autoscale_settings.max_throughput, null) != null && graph_params.throughput != null ? false : true
        ]
      ])
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at graph level."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.partition_key_version != null ? contains(["1", "2"], graph_params.partition_key_version) : true
        ]
      ])
    )
    error_message = "The 'partition_key_version' must be either '1' or '2' if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.index_policy.indexing_mode, null) != null ? contains(["consistent", "lazy", "none"], graph_params.index_policy.indexing_mode) : true
        ]
      ])
    )
    error_message = "The 'indexing_mode' must be one of 'consistent', 'lazy', or 'none' if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.conflict_resolution_policy.mode, null) != null ? contains(["LastWriterWins", "Custom"], graph_params.conflict_resolution_policy.mode) : true
        ]
      ])
    )
    error_message = "The 'conflict_resolution_policy.mode' must be either 'LastWriterWins' or 'Custom' if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.default_ttl != null ? graph_params.default_ttl == -1 || graph_params.default_ttl > 0 : true
        ]
      ])
    )
    error_message = "The 'default_ttl' must be either -1 (never expire) or a positive number if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.analytical_storage_ttl != null ? (graph_params.analytical_storage_ttl == -1 || (graph_params.analytical_storage_ttl >= 1 && graph_params.analytical_storage_ttl <= 2147483647)) : true
        ]
      ])
    )
    error_message = "The 'analytical_storage_ttl' must be either -1 (never expire) or between 1 and 2147483647 (excluding 0) if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          graph_params.partition_key_path != null && graph_params.partition_key_path != ""
        ]
      ])
    )
    error_message = "The 'partition_key_path' is required for all graphs and cannot be empty."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.index_policy.indexing_mode, null) != null && contains(["consistent", "lazy"], graph_params.index_policy.indexing_mode) ? (
            try(graph_params.index_policy.included_paths, null) != null && try(graph_params.index_policy.excluded_paths, null) != null
          ) : true
        ]
      ])
    )
    error_message = "When 'indexing_mode' is 'consistent' or 'lazy', both 'included_paths' and 'excluded_paths' are required."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.conflict_resolution_policy.mode, null) == "LastWriterWins" ? (
            try(graph_params.conflict_resolution_policy.conflict_resolution_path, null) != null
          ) : true
        ]
      ])
    )
    error_message = "When 'conflict_resolution_policy.mode' is 'LastWriterWins', 'conflict_resolution_path' is required."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.conflict_resolution_policy.mode, null) == "Custom" ? (
            try(graph_params.conflict_resolution_policy.conflict_resolution_procedure, null) != null
          ) : true
        ]
      ])
    )
    error_message = "When 'conflict_resolution_policy.mode' is 'Custom', 'conflict_resolution_procedure' is required."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        flatten([
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.index_policy.composite_index, null) != null ? [
            for composite_idx in graph_params.index_policy.composite_index :
            try(composite_idx.index, null) != null && length(composite_idx.index) > 0
          ] : [true]
        ])
      ])
    )
    error_message = "Each 'composite_index' must have at least one 'index' element defined."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        flatten([
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.index_policy.composite_index, null) != null ?
          flatten([
            for composite_idx in graph_params.index_policy.composite_index :
            [
              for index_elem in composite_idx.index :
              contains(["Ascending", "Descending"], index_elem.order)
            ]
          ]) : [true]
        ])
      ])
    )
    error_message = "Each composite index 'order' must be either 'Ascending' or 'Descending'."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.unique_key.paths, null) != null ? length(graph_params.unique_key.paths) > 0 : true
        ]
      ])
    )
    error_message = "The 'unique_key.paths' must contain at least one path if specified."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.gremlin_databases :
        [
          for graph_key, graph_params in db_params.graphs :
          try(graph_params.index_policy.included_paths, null) != null || try(graph_params.index_policy.excluded_paths, null) != null ? (
            contains(coalesce(graph_params.index_policy.included_paths, []), "/") || contains(coalesce(graph_params.index_policy.excluded_paths, []), "/")
          ) : true
        ]
      ])
    )
    error_message = "When 'index_policy' is specified, the root path '/' must be included in either 'included_paths' or 'excluded_paths'."
  }
}
