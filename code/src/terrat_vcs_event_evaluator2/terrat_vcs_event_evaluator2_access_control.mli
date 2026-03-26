module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  val eval_ci_change :
    Keys.Access_control_engine.t ->
    Terrat_change.Diff.t list ->
    ( Terrat_base_repo_config_v1.Access_control.Match.t list option,
      [> Terrat_access_control2.err ] )
    result
    Abb.Future.t

  val eval_files :
    Keys.Access_control_engine.t ->
    Terrat_change.Diff.t list ->
    ( (string * Terrat_base_repo_config_v1.Access_control.Match_list.t) option,
      [> Terrat_access_control2.err ] )
    result
    Abb.Future.t

  val eval_repo_config :
    Keys.Access_control_engine.t ->
    Terrat_change.Diff.t list ->
    ( Terrat_base_repo_config_v1.Access_control.Match_list.t option,
      [> Terrat_access_control2.err ] )
    result
    Abb.Future.t

  val eval_tf_operation :
    Keys.Access_control_engine.t ->
    Terrat_change_match3.Dirspace_config.t list ->
    [ `Apply of string list | `Apply_force | `Plan ] ->
    (Terrat_access_control2.R.t, [> Terrat_access_control2.err ]) result Abb.Future.t

  val plan_require_all_dirspace_access : Keys.Access_control_engine.t -> bool
  val apply_require_all_dirspace_access : Keys.Access_control_engine.t -> bool

  val eval_match_list :
    Keys.Access_control_engine.t ->
    Terrat_base_repo_config_v1.Access_control.Match_list.t ->
    (bool, [> Terrat_access_control2.err ]) result Abb.Future.t
end
