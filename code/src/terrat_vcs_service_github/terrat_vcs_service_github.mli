module type ROUTES = sig
  val routes :
    Terrat_config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make (Provider : Terrat_vcs_provider2_github.S) (Routes : ROUTES) : Terrat_vcs_service.S
