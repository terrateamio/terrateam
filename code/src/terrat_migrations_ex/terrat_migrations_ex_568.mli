val run_github :
  Terrat_config.t * Terrat_storage.t ->
  (unit, [ Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t

val run_gitlab :
  Terrat_config.t * Terrat_storage.t ->
  (unit, [ Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t
