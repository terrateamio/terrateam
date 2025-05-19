val fill_in_all :
  Terrat_config.t * Terrat_storage.t ->
  (unit, [ Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t
