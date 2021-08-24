val create : Terrat_storage.t -> Brtl_mw.Mw.t

val create_user_session : string -> ('a, 'b) Brtl_ctx.t -> ('a, 'b) Brtl_ctx.t

val rem_session :
  Terrat_storage.t ->
  ('a, 'b) Brtl_ctx.t ->
  (('a, 'b) Brtl_ctx.t, [> Pgsql_pool.err | Pgsql_io.err ]) result Abb.Future.t

val with_session :
  (string, 'a) Brtl_ctx.t ->
  (string, (string, [> `Location  of Uri.t | `Forbidden ]) Brtl_ctx.t) result Abb.Future.t
