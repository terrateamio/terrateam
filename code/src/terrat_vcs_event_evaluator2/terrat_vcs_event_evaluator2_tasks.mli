module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  val default_tasks : unit -> Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t
end
