module type S = sig
  type installation_id

  val namespace_prefix : string
  val route_root : unit -> ('a, 'a) Brtl_rtng.Route.t

  val enforce_installation_access :
    Terrat_storage.t ->
    Terrat_user.t ->
    installation_id ->
    ('a, 'b) Brtl_ctx.t ->
    (unit, ('a, [> `Forbidden | `Internal_server_error ]) Brtl_ctx.t) result Abb.Future.t
end

module Make
    (P : Terrat_vcs_provider2.S)
    (S : S with type installation_id = P.Api.Account.Id.t) : sig
  val routes :
    P.Api.Config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end
