module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  module Hmap = Hmap.Make (struct
    type 'a t = string
  end)

  type repo_config_fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err
  [@@deriving show]

  type err =
    [ `Missing_dep_err of string
    | `Error
    | `Msg_err of string
    | `Closed
    | repo_config_fetch_err
    | Terrat_change_match3.synthesize_config_err
    | `Suspend_eval of string
    | `Work_manifest_err of Uuidm.t
    | `Noop
    | Pgsql_io.err
    | Pgsql_pool.err
    | Str_template.err
    | P2.gate_add_approval_err
    ]
  [@@deriving show]

  module Key = struct
    type 'a t = ('a, err) result Hmap.key

    let add k v m = Hmap.add k (Ok v) m
  end

  module Work_manifest_event = struct
    type t =
      | Initiate of {
          work_manifest :
            ( S.Api.Account.t,
              ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
            Terrat_work_manifest3.Existing.t;
          run_id : string;
        }
      | Fail of {
          work_manifest :
            ( S.Api.Account.t,
              ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
            Terrat_work_manifest3.Existing.t;
          error : Terrat_vcs_provider2.run_work_manifest_err;
        }
      | Result of {
          work_manifest :
            ( S.Api.Account.t,
              ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
            Terrat_work_manifest3.Existing.t;
          result : Terrat_api_components.Work_manifest_result.t;
        }
  end

  module Pull_request_event = struct
    type t =
      | Open
      | Close
      | Sync
      | Ready_for_review
      | Comment of {
          comment_id : int;
          comment : Terrat_comment.t;
        }
  end

  module Access_control_engine = struct
    module Access_control = Terrat_access_control2.Make (struct
      type client = S.Api.Client.t
      type repo = S.Api.Repo.t

      include S.Access_control
    end)

    type t = {
      config : Terrat_base_repo_config_v1.Access_control.t;
      ctx : Access_control.Ctx.t;
      policy_branch : S.Api.Ref.t;
      request_id : string;
      user : string;
    }
  end

  module Matches = struct
    type t = {
      working_set_matches : Terrat_change_match3.Dirspace_config.t list;
          (* All unapplied matches in the current working layer *)
      all_matches : Terrat_change_match3.Dirspace_config.t list list;
          (* All matches broken up into layers in the order they must be applied. *)
      all_unapplied_matches : Terrat_change_match3.Dirspace_config.t list list;
          (* All unapplied layers in the order they must be applied *)
      all_tag_query_matches : Terrat_change_match3.Dirspace_config.t list list;
          (* All layers filtered by the tag query *)
      working_layer : Terrat_change_match3.Dirspace_config.t list;
          (* The all dirspaces configs in current layer, where "current" is
               defined as the first layer that does not have all of its
               dirspaces applied. *)
    }
    [@@deriving show]
  end

  (* Ya basic *)
  let account : S.Api.Account.t Key.t = Hmap.Key.create "account"
  let account_status : P2.Account_status.t Key.t = Hmap.Key.create "account_status"
  let client : S.Api.Client.t Key.t = Hmap.Key.create "client"

  let context : (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t Key.t =
    Hmap.Key.create "context"

  let context_id : Uuidm.t Key.t = Hmap.Key.create "context_id"

  let job :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t Key.t =
    Hmap.Key.create "job"

  let work_manifest_event_job :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t option
      Key.t =
    Hmap.Key.create "work_manifest_event_job"

  let pull_request_event : Pull_request_event.t Key.t = Hmap.Key.create "pull_request_event"
  let run_id : string Key.t = Hmap.Key.create "run_id"

  (* Different ways to access the branch we're working with  *)
  let default_branch_sha : S.Api.Ref.t Key.t = Hmap.Key.create "default_branch_sha"
  let branch_name : S.Api.Ref.t Key.t = Hmap.Key.create "branch_name"
  let branch_ref : S.Api.Ref.t Key.t = Hmap.Key.create "branch_ref"
  let dest_branch_name : S.Api.Ref.t Key.t = Hmap.Key.create "dest_branch_name"
  let dest_branch_ref : S.Api.Ref.t Key.t = Hmap.Key.create "dest_branch_ref"
  let working_branch_ref : S.Api.Ref.t Key.t = Hmap.Key.create "working_branch_ref"
  let working_branch_name : S.Api.Ref.t Key.t = Hmap.Key.create "working_branch_name"
  let initiator : Terrat_work_manifest3.Initiator.t Key.t = Hmap.Key.create "initiator"
  let pull_request_id : S.Api.Pull_request.Id.t Key.t = Hmap.Key.create "pull_request_id"
  let repo : S.Api.Repo.t Key.t = Hmap.Key.create "repo"
  let pushed_branch : S.Api.Ref.t Key.t = Hmap.Key.create "pushed_branch"

  let target : ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t Key.t
      =
    Hmap.Key.create "target"

  let user : S.Api.User.t option Key.t = Hmap.Key.create "user"

  (* Matches *)
  let matches : Matches.t Key.t = Hmap.Key.create "matches"

  let working_set_matches : Terrat_change_match3.Dirspace_config.t list Key.t =
    Hmap.Key.create "working_set_matches"

  let all_matches : Terrat_change_match3.Dirspace_config.t list list Key.t =
    Hmap.Key.create "all_matches"

  let all_unapplied_matches : Terrat_change_match3.Dirspace_config.t list list Key.t =
    Hmap.Key.create "all_unapplied_matches"

  let all_tag_query_matches : Terrat_change_match3.Dirspace_config.t list list Key.t =
    Hmap.Key.create "all_tag_query_matches"

  let working_layer : Terrat_change_match3.Dirspace_config.t list Key.t =
    Hmap.Key.create "working_layer"

  let out_of_change_applies : Terrat_dirspace.t list Key.t = Hmap.Key.create "out_of_change_applies"
  let applied_dirspaces : Terrat_dirspace.t list Key.t = Hmap.Key.create "applied_dirspaces"
  let changes : Terrat_change.Diff.t list Key.t = Hmap.Key.create "changes"

  let missing_autoplan_matches :
      (Terrat_change_match3.Dirspace_config.t list ->
      (Terrat_change_match3.Dirspace_config.t list, err) result Abb.Future.t)
      Key.t =
    Hmap.Key.create "missing_autoplan_matches"

  (* Work manifest state machine *)
  let work_manifest_event : Work_manifest_event.t option Key.t =
    Hmap.Key.create "work_manifest_event"

  let work_manifests_for_job :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "work_manifests_for_job"

  (* Compute node *)
  let compute_node_offering : Terrat_api_components.Work_manifest_initiate.t Key.t =
    Hmap.Key.create "compute_node_offering"

  let compute_node_id : Uuidm.t Key.t = Hmap.Key.create "compute_node_id"
  let compute_node : Terrat_job_context.Compute_node.t Key.t = Hmap.Key.create "compute_node"

  (* Pull request *)

  let pull_request : (Terrat_change.Diff.t list, bool) S.Api.Pull_request.t Key.t =
    Hmap.Key.create "pull_request"

  let pull_request_reviews : Terrat_pull_request_review.t list Key.t =
    Hmap.Key.create "pull_request_reviews"

  let pull_request_diff : Terrat_change.Diff.t list Key.t = Hmap.Key.create "pull_request_diff"
  let is_draft_pr : bool Key.t = Hmap.Key.create "is_draft_pr"
  let maybe_automerge : unit Key.t = Hmap.Key.create "maybe_automerge"

  (* Indexer branch *)
  let repo_index_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "repo_index_branch_wm_completed"

  let built_repo_index_branch : Terrat_base_repo_config_v1.Index.t Key.t =
    Hmap.Key.create "built_repo_index_branch"

  let repo_index_branch : Terrat_base_repo_config_v1.Index.t Key.t =
    Hmap.Key.create "repo_index_branch"

  (* Indexer dest branch *)
  let repo_index_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "repo_index_dest_branch_wm_completed"

  let built_repo_index_dest_branch : Terrat_base_repo_config_v1.Index.t Key.t =
    Hmap.Key.create "built_repo_index_dest_branch"

  let repo_index_dest_branch : Terrat_base_repo_config_v1.Index.t Key.t =
    Hmap.Key.create "repo_index_dest_branch"

  (* Repo tree branch *)
  let repo_tree_branch : string list Key.t = Hmap.Key.create "repo_tree_branch"

  let repo_tree_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "repo_tree_branch_wm_completed"

  let built_repo_tree_branch : string list Key.t = Hmap.Key.create "built_repo_tree_branch"

  (* Repo tree dest branch *)
  let repo_tree_dest_branch : string list Key.t = Hmap.Key.create "repo_tree_dest_branch"

  let repo_tree_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "repo_tree_dest_branch_wm_completed"

  let built_repo_tree_dest_branch : string list Key.t =
    Hmap.Key.create "built_repo_tree_dest_branch"

  let repo_tree_dest_branch : string list Key.t = Hmap.Key.create "repo_tree_dest_branch"

  (* Built repo config branch *)
  let built_repo_config_branch : Yojson.Safe.t option Key.t =
    Hmap.Key.create "built_repo_config_branch"

  let built_repo_config_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "built_repo_config_branch_wm_completed"

  (* Repository config branch *)
  let repo_config_system_defaults :
      Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t Key.t =
    Hmap.Key.create "repo_config_system_defaults"

  let repo_config_raw' :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_raw'"

  let repo_config_raw :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_raw"

  let repo_config_with_provenance :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_with_provenance"

  let repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Key.t =
    Hmap.Key.create "repo_config"

  let derived_repo_config_empty_index :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "derived_repo_config_empty_index"

  let derived_repo_config :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "derived_repo_config"

  let synthesized_config_empty_index : Terrat_change_match3.Config.t Key.t =
    Hmap.Key.create "synthesized_config_empty_index"

  let synthesized_config : Terrat_change_match3.Config.t Key.t =
    Hmap.Key.create "synthesized_config"

  let dest_branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Key.t =
    Hmap.Key.create "dest_branch_dirspaces"

  let store_stacks : unit Key.t = Hmap.Key.create "store_stacks"

  (* Built repo config branch *)
  let built_repo_config_dest_branch : Yojson.Safe.t option Key.t =
    Hmap.Key.create "built_repo_config_dest_branch"

  let built_repo_config_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Key.t =
    Hmap.Key.create "built_repo_config_dest_branch_wm_completed"

  (* Repository config dest branch *)
  let repo_config_dest_branch_raw' :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_dest_branch_raw'"

  let repo_config_dest_branch_raw :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_dest_branch_raw"

  let repo_config_dest_branch_with_provenance :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "repo_config_dest_branch_with_provenance"

  let repo_config_dest_branch :
      Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Key.t =
    Hmap.Key.create "repo_config_dest_branch"

  let derived_repo_config_dest_branch_empty_index :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "derived_repo_config_dest_branch_empty_index"

  let derived_repo_config_dest_branch :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Key.t =
    Hmap.Key.create "derived_repo_config_dest_branch"

  let synthesized_config_dest_branch_empty_index : Terrat_change_match3.Config.t Key.t =
    Hmap.Key.create "synthesized_config_dest_branch_empty_index"

  let synthesized_config_dest_branch : Terrat_change_match3.Config.t Key.t =
    Hmap.Key.create "synthesized_config_dest_branch"

  (* Index *)
  let publish_index_complete : unit Key.t = Hmap.Key.create "publish_index_complete"

  (* Unlocks *)
  let publish_unlock : unit Key.t = Hmap.Key.create "publish_unlock"

  (* Dirspaces *)
  let dest_branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Key.t =
    Hmap.Key.create "dest_branch_dirspaces"

  let branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Key.t =
    Hmap.Key.create "branch_dirspaces"

  let publish_repo_config : unit Key.t = Hmap.Key.create "publish_repo_config"
  let comment_id : int option Key.t = Hmap.Key.create "comment_id"
  let react_to_comment : unit Key.t = Hmap.Key.create "react_to_comment"
  let work_manifest_id : Uuidm.t option Key.t = Hmap.Key.create "work_manifest_id"

  let work_manifest :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Key.t =
    Hmap.Key.create "work_manifest"

  let access_control : Access_control_engine.t Key.t = Hmap.Key.create "access_control"

  let access_control_eval_plan :
      (Terrat_access_control2.R.t, Terrat_access_control2.err) result Key.t =
    Hmap.Key.create "access_control_eval_plan"

  let access_control_eval_apply :
      (Terrat_access_control2.R.t, Terrat_access_control2.err) result Key.t =
    Hmap.Key.create "access_control_eval_apply"

  let update_context_branch_hashes : unit Key.t = Hmap.Key.create "update_context_branch_hashes"

  let check_apply_requirements : S.Apply_requirements.Result.t Key.t =
    Hmap.Key.create "check_apply_requirements"

  let check_access_control_ci_change : unit Key.t = Hmap.Key.create "check_access_control_ci_change"
  let check_access_control_files : unit Key.t = Hmap.Key.create "check_access_control_files"

  let check_access_control_repo_config : unit Key.t =
    Hmap.Key.create "check_access_control_repo_config"

  let check_valid_destination_branch : unit Key.t = Hmap.Key.create "check_valid_destination_branch"
  let check_access_control_plan : unit Key.t = Hmap.Key.create "check_access_control_plan"
  let check_access_control_apply : unit Key.t = Hmap.Key.create "check_access_control_apply"
  let check_account_status_expired : unit Key.t = Hmap.Key.create "check_account_status_expired"
  let check_account_tier : unit Key.t = Hmap.Key.create "check_account_tier"
  let check_merge_conflict : unit Key.t = Hmap.Key.create "check_merge_conflict"

  let check_conflicting_plan_work_manifests : unit Key.t =
    Hmap.Key.create "check_conflicting_plan_work_manifests"

  let check_conflicting_apply_work_manifests : unit Key.t =
    Hmap.Key.create "check_conflicting_apply_work_manifests"

  let check_dirspaces_missing_plans : unit Key.t = Hmap.Key.create "check_dirspaces_missing_plans"
  let check_dirspaces_to_plan : unit Key.t = Hmap.Key.create "check_dirspaces_to_plan"
  let check_dirspaces_to_apply : unit Key.t = Hmap.Key.create "check_dirspaces_to_apply"
  let check_gates : unit Key.t = Hmap.Key.create "check_gates"
  let store_gate_approval : unit Key.t = Hmap.Key.create "store_gate_approval"

  let check_dirspaces_owned_by_other_pull_requests : unit Key.t =
    Hmap.Key.create "check_dirspaces_owned_by_other_pull_requests"

  let check_pull_request_state : unit Key.t = Hmap.Key.create "check_pull_request_state"

  let maybe_create_completed_apply_check : unit Key.t =
    Hmap.Key.create "maybe_create_completed_apply_check"

  let can_run_plan : unit Key.t = Hmap.Key.create "can_run_plan"
  let run_plan : unit Key.t = Hmap.Key.create "run_plan"
  let can_run_apply : unit Key.t = Hmap.Key.create "can_run_apply"
  let run_apply : unit Key.t = Hmap.Key.create "run_apply"
  let run_next_layer : unit Key.t = Hmap.Key.create "run_next_layer"
  let complete_no_change_dirspaces : unit Key.t = Hmap.Key.create "complete_no_change_dirspaces"
  let maybe_complete_job : unit Key.t = Hmap.Key.create "maybe_complete_job"

  let maybe_complete_job_from_work_manifest_event : unit Key.t =
    Hmap.Key.create "maybe_complete_job_from_work_manifest_event"

  (* Actions *)

  let publish_comment :
      (( S.Api.Account.t,
         S.Db.t,
         (unit, unit) S.Api.Pull_request.t,
         ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) P2.Target.t,
         S.Apply_requirements.Result.t,
         S.Api.Config.t )
       P2.Msg.t ->
      (unit, [ `Error ]) result Abb.Future.t)
      Key.t =
    Hmap.Key.create "publish_comment"

  let create_commit_checks :
      (S.Api.Ref.t -> Terrat_commit_check.t list -> (unit, [ `Error ]) result Abb.Future.t) Key.t =
    Hmap.Key.create "create_commit_checks"

  let publish_dest_branch_no_match : unit Key.t = Hmap.Key.create "publish_dest_branch_no_match"

  (* Context management *)

  let store_repository : unit Key.t = Hmap.Key.create "store_repository"
  let store_pull_request : unit Key.t = Hmap.Key.create "store_pull_request"
  let tag_query : Terrat_tag_query.t Key.t = Hmap.Key.create "tag_query"

  (* API facing targets *)

  let get_context_for_pull_request :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t Key.t =
    Hmap.Key.create "get_context_for_pull_request"

  let eval_compute_node_poll : Terrat_api_components.Work_manifest.t Key.t =
    Hmap.Key.create "eval_compute_node_poll"

  let eval_work_manifest_event : unit Key.t = Hmap.Key.create "eval_work_manifest_event"

  let eval_pull_request_event :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t Key.t =
    Hmap.Key.create "eval_pull_request_event"

  let iter_job : unit Key.t = Hmap.Key.create "iter_job"
  let eval_work_manifest_failure : unit Key.t = Hmap.Key.create "eval_work_manifest_failure"
  let eval_push_event : unit Key.t = Hmap.Key.create "eval_push_event"
  let run_missing_drift_schedules : unit Key.t = Hmap.Key.create "run_missing_drift_schedules"
end
