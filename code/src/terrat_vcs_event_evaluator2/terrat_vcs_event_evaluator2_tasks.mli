module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  (** Add tasks for targets which can be inferred from the event. *)
  val of_work_manifest_tasks :
    ( S.Api.Account.t,
      (('a, 'b) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t ->
    Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t

  val default_tasks : unit -> Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t

  val make_tasks :
    Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t ->
    Terrat_vcs_event_evaluator2_builder.Make(S).Bs.Tasks.t
end
