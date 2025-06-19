include
  Terrat_vcs_api.S
    with type Account.Id.t = int
     and type Config.vcs_config = Terrat_config.Gitlab.t
     and type Client.native = Openapic_abb.t
     and type User.Id.t = string
     and type Pull_request.Id.t = int
     and type Repo.Id.t = int
