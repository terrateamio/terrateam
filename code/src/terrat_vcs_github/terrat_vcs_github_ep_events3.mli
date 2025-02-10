module Make
    (Terratc :
      Terratc_intf.S
        with type Github.Client.t = Terrat_vcs_github.S.Client.t
         and type Github.Account.t = Terrat_vcs_github.S.Account.t
         and type Github.Repo.t = Terrat_vcs_github.S.Repo.t
         and type Github.Remote_repo.t = Terrat_vcs_github.S.Remote_repo.t
         and type Github.Ref.t = Terrat_vcs_github.S.Ref.t) : sig
  val post : Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
