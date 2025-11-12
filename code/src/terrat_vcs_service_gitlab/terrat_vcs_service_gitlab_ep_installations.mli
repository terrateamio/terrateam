module type S = sig
  module Account_id : Terrat_vcs_api.ID

  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    Account_id.t ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module Make (S : S with type Account_id.t = int) : sig
  module List : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
  end

  module Webhook : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      Brtl_rtng.Handler.t
  end

  module List_repos : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      string Brtl_ep_paginate.Param.t option ->
      int ->
      Brtl_rtng.Handler.t
  end

  module List_dirspaces : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      string option ->
      string option ->
      (string * string * string * Uuidm.t) Brtl_ep_paginate.Param.t option ->
      int ->
      Brtl_rtng.Handler.t
  end

  module List_work_manifest_outputs : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      Uuidm.t ->
      string option ->
      string option ->
      int Brtl_ep_paginate.Param.t option ->
      int ->
      bool ->
      Brtl_rtng.Handler.t
  end

  module List_work_manifests : sig
    val get :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      string option ->
      string option ->
      (string * Uuidm.t) Brtl_ep_paginate.Param.t option ->
      int ->
      Brtl_rtng.Handler.t
  end

  module Token : sig
    val put :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      Terrat_api_components_gitlab_access_token.t ->
      Brtl_rtng.Handler.t
  end

  module Email : sig
    val put :
      Terrat_vcs_service_gitlab_provider.Api.Config.t ->
      Terrat_storage.t ->
      int ->
      Terrat_api_gitlab_installations.Update_email.Request_body.t ->
      Brtl_rtng.Handler.t
  end
end
