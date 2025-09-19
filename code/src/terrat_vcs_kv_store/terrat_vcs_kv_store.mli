module type S = sig
  module Installation_id : Terrat_vcs_api.ID

  val namespace_prefix : string
  val route_root : unit -> ('a, 'a) Brtl_rtng.Route.t

  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    Installation_id.t ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module Make
    (P : Terrat_vcs_provider2.S)
    (S : S with type Installation_id.t = P.Api.Account.Id.t) : sig
  val routes :
    P.Api.Config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end
