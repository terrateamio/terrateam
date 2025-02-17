module Make (P : Terrat_vcs_provider2_github.S) : sig
  module Initiate : sig
    val post :
      Terrat_config.t ->
      Terrat_storage.t ->
      Uuidm.t ->
      Terrat_api_work_manifest.Initiate.Request_body.t ->
      Brtl_rtng.Handler.t
  end

  module Plans : sig
    val post :
      Terrat_config.t ->
      Terrat_storage.t ->
      Uuidm.t ->
      Terrat_api_work_manifest.Plan_create.Request_body.t ->
      Brtl_rtng.Handler.t

    val get :
      Terrat_config.t -> Terrat_storage.t -> Uuidm.t -> string -> string -> Brtl_rtng.Handler.t
  end

  module Results : sig
    val put :
      Terrat_config.t ->
      Terrat_storage.t ->
      Uuidm.t ->
      Terrat_api_work_manifest.Results.Request_body.t ->
      Brtl_rtng.Handler.t
  end

  module Access_token : sig
    val post : Terrat_config.t -> Terrat_storage.t -> Uuidm.t -> Brtl_rtng.Handler.t
  end
end
