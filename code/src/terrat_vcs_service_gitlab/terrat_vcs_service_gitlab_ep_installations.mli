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
