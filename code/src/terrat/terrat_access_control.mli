type query_err = [ `Error ] [@@deriving show]
type err = query_err [@@deriving show]

module Policy : sig
  type t = {
    tag_query : Terrat_tag_query.t;
    policy : Terrat_base_repo_config_v1.Access_control.Match_list.t;
  }
  [@@deriving show]
end

module R : sig
  module Deny : sig
    type t = {
      change_match : Terrat_change_match3.Dirspace_config.t;
      policy : Terrat_base_repo_config_v1.Access_control.Match_list.t option;
    }
    [@@deriving show]
  end

  type t = {
    pass : Terrat_change_match3.Dirspace_config.t list;
    deny : Deny.t list;
  }
  [@@deriving show]
end

module type S = sig
  module Ctx : sig
    type t
  end

  val query :
    Ctx.t ->
    Terrat_base_repo_config_v1.Access_control.Match.t ->
    (bool, [> query_err ]) result Abb.Future.t

  val is_ci_changed : Ctx.t -> Terrat_change.Diff.t list -> (bool, [> err ]) result Abb.Future.t
  val set_user : string -> Ctx.t -> Ctx.t
end

module Make (S : S) : sig
  (** Test if any of the CI configuration has changed. Return [true] if no CI
      changes have been detected or they were detected but passed the
      permissions check. *)
  val eval_ci_change :
    S.Ctx.t ->
    Terrat_base_repo_config_v1.Access_control.Match_list.t ->
    Terrat_change.Diff.t list ->
    (bool, [> err ]) result Abb.Future.t

  (** Test if any files changed violate the files policy.  Return [`Ok] if no
      files matching a policy changed or the files matched pass the policy,
      returns [`Denied filename] for the first file that failed the check. *)
  val eval_files :
    S.Ctx.t ->
    Terrat_base_repo_config_v1.Access_control.Match_list.t Terrat_data.String_map.t ->
    Terrat_change.Diff.t list ->
    ( [ `Ok | `Denied of string * Terrat_base_repo_config_v1.Access_control.Match_list.t ],
      [> err ] )
    result
    Abb.Future.t

  (** Test if there is a repo config change and it passes the
      configuration. [true] is returned if there is no repo configuration change
      or there is and it passes the permissions check. *)
  val eval_repo_config :
    S.Ctx.t ->
    Terrat_base_repo_config_v1.Access_control.Match_list.t ->
    Terrat_change.Diff.t list ->
    (bool, [> err ]) result Abb.Future.t

  (** Evaluate a policy and a list of changes.  Policies are evaluating in
      order, comparing to the first one that has a matching tag query.  The
      result partitions the passing and deny.  All input changes will be
      represented in these two.. *)
  val eval :
    S.Ctx.t ->
    Policy.t list ->
    Terrat_change_match3.Dirspace_config.t list ->
    (R.t, [> err ]) result Abb.Future.t

  val eval_match_list :
    S.Ctx.t ->
    Terrat_base_repo_config_v1.Access_control.Match_list.t ->
    (bool, [> err ]) result Abb.Future.t
end
