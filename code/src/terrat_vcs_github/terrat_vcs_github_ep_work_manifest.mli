module Make
    (Terratc :
      Terratc_intf.S
        with type Github.Client.t = Terrat_vcs_github.S.Client.t
         and type Github.Account.t = Terrat_vcs_github.S.Account.t
         and type Github.Repo.t = Terrat_vcs_github.S.Repo.t
         and type Github.Remote_repo.t = Terrat_vcs_github.S.Remote_repo.t
         and type Github.Ref.t = Terrat_vcs_github.S.Ref.t) : sig
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
