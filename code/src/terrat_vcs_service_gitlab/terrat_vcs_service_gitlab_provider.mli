include
  Terrat_vcs_provider2.S
    with type Api.Config.t = Terrat_vcs_api_gitlab.Config.t
    with type Api.Config.vcs_config = Terrat_vcs_api_gitlab.Config.vcs_config
     and type Api.Pull_request.Id.t = Terrat_vcs_api_gitlab.Pull_request.Id.t
     and type Api.Repo.t = Terrat_vcs_api_gitlab.Repo.t
     and type Api.Account.t = Terrat_vcs_api_gitlab.Account.t
     and type Api.Ref.t = Terrat_vcs_api_gitlab.Ref.t
     and type Api.User.t = Terrat_vcs_api_gitlab.User.t
     and type Api.Client.t = Terrat_vcs_api_gitlab.Client.t
