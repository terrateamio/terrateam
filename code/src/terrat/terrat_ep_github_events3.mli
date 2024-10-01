module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = Terrat_github_evaluator3.S.Client.t
                  and type Github.Account.t = Terrat_github_evaluator3.S.Account.t
                  and type Github.Repo.t = Terrat_github_evaluator3.S.Repo.t
                  and type Github.Remote_repo.t = Terrat_github_evaluator3.S.Remote_repo.t
                  and type Github.Ref.t = Terrat_github_evaluator3.S.Ref.t) : sig
  val post : Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
