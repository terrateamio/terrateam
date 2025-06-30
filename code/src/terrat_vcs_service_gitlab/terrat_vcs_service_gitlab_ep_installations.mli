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
