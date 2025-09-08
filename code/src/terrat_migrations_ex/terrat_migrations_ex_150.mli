val fill_in_all :
  Terrat_config.t * Terrat_storage.t * Pgsql_io.t ->
  (unit, [ Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t
