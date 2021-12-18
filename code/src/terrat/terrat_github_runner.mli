type err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | Terrat_github.get_installation_access_token_err
  ]
[@@deriving show]

val run :
  request_id:string -> Terrat_config.t -> Terrat_storage.t -> (unit, [> err ]) result Abb.Future.t
