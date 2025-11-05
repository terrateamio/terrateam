type err =
  [ Pgsql_io.err
  | Pgsql_pool.err
  | Terrat_github.Oauth.refresh_err
  ]
[@@deriving show]

val get_token :
  Terrat_vcs_service_github_provider.Api.Config.t ->
  Terrat_storage.t ->
  Terrat_user.t ->
  (string, [> err ]) result Abb.Future.t

val enforce_installation_access :
  Terrat_storage.t ->
  Terrat_user.t ->
  int ->
  ('a, 'b) Brtl_ctx.t ->
  (unit, ('a, [> `Forbidden | `Internal_server_error ]) Brtl_ctx.t) result Abb.Future.t
