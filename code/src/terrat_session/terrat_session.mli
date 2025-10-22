val create : Terrat_storage.t -> Brtl_mw.Mw.t Abb.Future.t
val create_user_session : Terrat_user.t -> ('a, 'b) Brtl_ctx.t -> ('a, 'b) Brtl_ctx.t

val rem_session :
  Terrat_storage.t ->
  ('a, 'b) Brtl_ctx.t ->
  (('a, 'b) Brtl_ctx.t, [> Pgsql_pool.err | Pgsql_io.err ]) result Abb.Future.t

(** If a user is authenticated, continue with the operation otherwise fail. If [caps] is specified,
    the user must be authenticated with the provided capabilities. *)
val with_session :
  ?caps:Terrat_user.Capability.t list ->
  (string, 'a) Brtl_ctx.t ->
  (Terrat_user.t, (string, [> `Location of Uri.t | `Forbidden ]) Brtl_ctx.t) result Abb.Future.t
