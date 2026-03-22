module type S = sig
  val vcs : string
  val read_sql : string -> string option
end

module Make
    (P : Terrat_vcs_provider2.S with type Api.Account.Id.t = int and type Api.User.Id.t = string)
    (_ : S) : sig
  val routes :
    P.Api.Config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end
