type get_access_token_err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Refresh_token_err of Githubc_v3.call_err
  | `Renew_refresh_token
  ]

type verify_user_installation_access_err =
  [ get_access_token_err
  | Githubc_v3.call_err
  | `Forbidden
  ]

type get_user_installations_err =
  [ get_access_token_err
  | Githubc_v3.call_err
  ]

val show_get_access_token_err : get_access_token_err -> string

val pp_get_access_token_err : Format.formatter -> get_access_token_err -> unit

val show_verify_user_installation_access_err : verify_user_installation_access_err -> string

val pp_verify_user_installation_access_err :
  Format.formatter -> verify_user_installation_access_err -> unit

val show_get_user_installations_err : get_user_installations_err -> string

val pp_get_user_installations_err : Format.formatter -> get_user_installations_err -> unit

val create :
  Githubc_v3.Schema.t ->
  Githubc_v3.Authorization.t ->
  (Githubc_v3.t, [> Githubc_v3.call_err ]) result Abb.Future.t

val get_access_token :
  Terrat_storage.t ->
  string ->
  string ->
  string ->
  (string, [> get_access_token_err ]) result Abb.Future.t

val get_user_installations :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  string ->
  (Terrat_data.Response.Installation.t list, [> get_user_installations_err ]) result Abb.Future.t

val verify_user_installation_access :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  string ->
  (unit, [> verify_user_installation_access_err ]) result Abb.Future.t

val verify_admin_installation_access :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  string ->
  (unit, [> verify_user_installation_access_err ]) result Abb.Future.t
