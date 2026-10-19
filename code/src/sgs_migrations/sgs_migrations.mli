val run :
  Sgs_config.t ->
  Pgsql_pool.t ->
  ( unit,
    [> `Migration_err of [ Pgsql_io.err | Pgsql_pool.err | `Mql_err of Mql.Ast.err ]
    | `Consistency_err of Data_mig.Error.Consistency.t
    ] )
  result
  Abb.Future.t
