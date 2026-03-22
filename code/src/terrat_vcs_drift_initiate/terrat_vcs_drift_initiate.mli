module type S = sig
  val vcs : string
end

module Make (P : Terrat_vcs_provider2.S with type Api.Account.Id.t = int) (_ : S) : sig
  val routes :
    P.Api.Config.t ->
    Terrat_storage.t ->
    Terrat_vcs_event_evaluator2.Exec.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end
