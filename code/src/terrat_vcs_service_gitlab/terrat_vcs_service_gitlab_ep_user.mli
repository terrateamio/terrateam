module Whoami : sig
  val get :
    Terrat_vcs_service_gitlab_provider.Api.Config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
