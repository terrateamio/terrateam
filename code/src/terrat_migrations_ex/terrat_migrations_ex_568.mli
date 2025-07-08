val run :
  Terrat_config.t * Terrat_storage.t ->
  (unit, [ Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t
