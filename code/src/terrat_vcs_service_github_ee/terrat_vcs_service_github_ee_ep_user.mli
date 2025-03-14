module Installations : sig
  val get :
    Terrat_vcs_service_github_provider.Api.Config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
