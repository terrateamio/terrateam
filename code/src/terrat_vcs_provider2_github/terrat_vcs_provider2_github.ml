module type S =
  Terrat_vcs_provider2.S
    with type Api.Account.Id.t = int
     and type Api.User.Id.t = string
     and type Api.Pull_request.Id.t = int
     and type Api.Repo.Id.t = int
