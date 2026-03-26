module Make (P : Terrat_vcs_provider2_gitlab.S) : sig
  val post :
    P.Api.Config.t -> Terrat_storage.t -> Terrat_vcs_event_evaluator2.Exec.t -> Brtl_rtng.Handler.t
end
