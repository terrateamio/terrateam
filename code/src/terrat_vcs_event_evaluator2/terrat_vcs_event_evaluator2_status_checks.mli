(** Whether the per-dirspace commit checks of a run are created for a pull request, beside the
    notifications setting of the run. *)

(** The largest number of dirspaces a pull request may impact and still get its per-dirspace plan
    checks. One impacted dirspace gets one plan check over the life of the pull request, thus the
    count is the number of plan checks the pull request would get. Above it the checks are not
    created, which is the behaviour of notifications.plan.status_checks turned off. *)
val plan_threshold : int

(** The same cap for the per-dirspace apply checks: notifications.apply.status_checks turned off
    above it. *)
val apply_threshold : int

(** The number of distinct dirspaces of the given layers. A dirspace which appears in more than one
    layer is counted once, as one dirspace gets one check of a run type. *)
val impacted_dirspaces : Terrat_dirspace.t list list -> int

(** [enabled ~notifications ~impacted_dirspaces ~run] is whether the per-dirspace checks of [run]
    are created. The notifications setting decides, and above the threshold of [run] the answer is
    [false] whatever that setting says. [`Other] is a run with no setting of its own, for instance
    an index build, and it keeps its checks. *)
val enabled :
  notifications:Terrat_base_repo_config_v1.Notifications.t ->
  impacted_dirspaces:int ->
  run:[ `Plan | `Apply | `Other ] ->
  bool
