type err =
  [ Pgsql_io.err
  | Pgsql_pool.err
  | `Error
  ]
[@@deriving show]

val get_token :
  Terrat_config.t -> Terrat_storage.t -> Terrat_user.t -> (string, [> err ]) result Abb.Future.t
