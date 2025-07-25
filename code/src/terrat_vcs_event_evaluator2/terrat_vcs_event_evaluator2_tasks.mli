module Make (S : Terrat_vcs_provider2.S) : sig
  val add_tasks :
    Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t ->
    Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t
end
