module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = Terrat_github_evaluator3.S.Client.t
                  and type Github.Repo.t = Terrat_github_evaluator3.S.Repo.t
                  and type Github.Remote_repo.t = Terrat_github_evaluator3.S.Remote_repo.t
                  and type Github.Ref.t = Terrat_github_evaluator3.S.Ref.t) : sig
  val run : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
end
