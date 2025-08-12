module type ROUTES = sig
  type config

  val routes :
    config ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make
    (Provider :
      Terrat_vcs_provider2_gitlab.S
        with type Api.Config.t = Terrat_vcs_service_gitlab_provider.Api.Config.t)
    (Routes : ROUTES with type config = Provider.Api.Config.t) :
  Terrat_vcs_service.S with type Service.vcs_config = Provider.Api.Config.vcs_config
