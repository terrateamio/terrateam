module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  module Hmap = Hmap.Make (struct
    type 'a t = string
  end)

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
        }
      | Result of {
          work_manifest :
            ( S.Api.Account.t,
              ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
            Terrat_work_manifest3.Existing.t;
          result : Terrat_api_components.Work_manifest_result.t;
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
  let account : S.Api.Account.t Hmap.key = Hmap.Key.create "account"
  let account_status : P2.Account_status.t Hmap.key = Hmap.Key.create "account_status"
  let branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_name"
  let branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_ref"
  let client : S.Api.Client.t Hmap.key = Hmap.Key.create "client"

  let context : (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t Hmap.key =
    Hmap.Key.create "context"

  let context_id : Uuidm.t Hmap.key = Hmap.Key.create "context_id"
  let default_branch_sha : S.Api.Ref.t Hmap.key = Hmap.Key.create "default_branch_sha"
  let dest_branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_name"
  let dest_branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_ref"
  let initiator : Terrat_work_manifest3.Initiator.t Hmap.key = Hmap.Key.create "initiator"
  let is_interactive : bool Hmap.key = Hmap.Key.create "is_interactive"

  let job :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t Hmap.key
      =
    Hmap.Key.create "job"

  let pull_request_id : S.Api.Pull_request.Id.t Hmap.key = Hmap.Key.create "pull_request_id"
  let repo : S.Api.Repo.t Hmap.key = Hmap.Key.create "repo"

  let target :
      ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t Hmap.key =
    Hmap.Key.create "target"

  let user : S.Api.User.t option Hmap.key = Hmap.Key.create "user"
  let working_branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "working_branch_ref"

  (* Matches *)
  let matches : Matches.t Hmap.key = Hmap.Key.create "matches"

  let working_set_matches : Terrat_change_match3.Dirspace_config.t list Hmap.key =
    Hmap.Key.create "working_set_matches"

  let all_matches : Terrat_change_match3.Dirspace_config.t list list Hmap.key =
    Hmap.Key.create "all_matches"

  let all_unapplied_matches : Terrat_change_match3.Dirspace_config.t list list Hmap.key =
    Hmap.Key.create "all_unapplied_matches"

  let all_tag_query_matches : Terrat_change_match3.Dirspace_config.t list list Hmap.key =
    Hmap.Key.create "all_tag_query_matches"

  let working_layer : Terrat_change_match3.Dirspace_config.t list Hmap.key =
    Hmap.Key.create "working_layer"

  (* Work manifest state machine *)
  let work_manifest_event : Work_manifest_event.t option Hmap.key =
    Hmap.Key.create "work_manifest_event"

  let work_manifests_for_job :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Hmap.key =
    Hmap.Key.create "work_manifests_for_job"

  (* Compute node *)
  let compute_node_offering : Terrat_api_components.Work_manifest_initiate.t Hmap.key =
    Hmap.Key.create "compute_node_offering"

  let compute_node_id : Uuidm.t Hmap.key = Hmap.Key.create "compute_node_id"
  let compute_node : Terrat_job_context.Compute_node.t Hmap.key = Hmap.Key.create "compute_node"

  (* Pull request *)
  let pull_request : (Terrat_change.Diff.t list, bool) S.Api.Pull_request.t Hmap.key =
    Hmap.Key.create "pull_request"

  let pull_request_diff : Terrat_change.Diff.t list Hmap.key = Hmap.Key.create "pull_request_diff"

  (* Indexer branch *)
  let repo_index_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "repo_index_branch_wm_completed"

  let built_repo_index_branch : Terrat_base_repo_config_v1.Index.t Hmap.key =
    Hmap.Key.create "built_repo_index_branch"

  let repo_index_branch : Terrat_base_repo_config_v1.Index.t Hmap.key =
    Hmap.Key.create "repo_index_branch"

  (* Indexer dest branch *)
  let repo_index_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "repo_index_dest_branch_wm_completed"

  let built_repo_index_dest_branch : Terrat_base_repo_config_v1.Index.t Hmap.key =
    Hmap.Key.create "built_repo_index_dest_branch"

  let repo_index_dest_branch : Terrat_base_repo_config_v1.Index.t Hmap.key =
    Hmap.Key.create "repo_index_dest_branch"

  (* Repo tree branch *)
  let repo_tree_branch : string list Hmap.key = Hmap.Key.create "repo_tree_branch"

  let repo_tree_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "repo_tree_branch_wm_completed"

  let built_repo_tree_branch : string list Hmap.key = Hmap.Key.create "built_repo_tree_branch"

  (* Repo tree dest branch *)
  let repo_tree_dest_branch : string list Hmap.key = Hmap.Key.create "repo_tree_dest_branch"

  let repo_tree_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "repo_tree_dest_branch_wm_completed"

  let built_repo_tree_dest_branch : string list Hmap.key =
    Hmap.Key.create "built_repo_tree_dest_branch"

  let repo_tree_dest_branch : string list Hmap.key = Hmap.Key.create "repo_tree_dest_branch"

  (* Built repo config branch *)
  let built_repo_config_branch : Yojson.Safe.t option Hmap.key =
    Hmap.Key.create "built_repo_config_branch"

  let built_repo_config_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "built_repo_config_branch_wm_completed"

  (* Repository config branch *)
  let repo_config_system_defaults :
      Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t Hmap.key =
    Hmap.Key.create "repo_config_system_defaults"

  let repo_config_raw' :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_raw'"

  let repo_config_raw :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_raw"

  let repo_config_with_provenance :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_with_provenance"

  let repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Hmap.key =
    Hmap.Key.create "repo_config"

  let derived_repo_config_empty_index :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "derived_repo_config_empty_index"

  let derived_repo_config :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "derived_repo_config"

  let synthesized_config_empty_index : Terrat_change_match3.Config.t Hmap.key =
    Hmap.Key.create "synthesized_config_empty_index"

  let synthesized_config : Terrat_change_match3.Config.t Hmap.key =
    Hmap.Key.create "synthesized_config"

  let dest_branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Hmap.key =
    Hmap.Key.create "dest_branch_dirspaces"

  (* Built repo config branch *)
  let built_repo_config_dest_branch : Yojson.Safe.t option Hmap.key =
    Hmap.Key.create "built_repo_config_dest_branch"

  let built_repo_config_dest_branch_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "built_repo_config_dest_branch_wm_completed"

  (* Repository config dest branch *)
  let repo_config_dest_branch_raw' :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_dest_branch_raw'"

  let repo_config_dest_branch_raw :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_dest_branch_raw"

  let repo_config_dest_branch_with_provenance :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_dest_branch_with_provenance"

  let repo_config_dest_branch :
      Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Hmap.key =
    Hmap.Key.create "repo_config_dest_branch"

  let derived_repo_config_dest_branch_empty_index :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "derived_repo_config_dest_branch_empty_index"

  let derived_repo_config_dest_branch :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "derived_repo_config_dest_branch"

  let synthesized_config_dest_branch_empty_index : Terrat_change_match3.Config.t Hmap.key =
    Hmap.Key.create "synthesized_config_dest_branch_empty_index"

  let synthesized_config_dest_branch : Terrat_change_match3.Config.t Hmap.key =
    Hmap.Key.create "synthesized_config"

  (* Unlocks *)
  let publish_unlock : unit Hmap.key = Hmap.Key.create "publish_unlock"

  (* Dirspaces *)
  let dest_branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Hmap.key =
    Hmap.Key.create "dest_branch_dirspaces"

  let branch_dirspaces : Terrat_api_components.Work_manifest_dir.t list Hmap.key =
    Hmap.Key.create "branch_dirspaces"

  let publish_repo_config : unit Hmap.key = Hmap.Key.create "publish_repo_config"
  let comment_id : int Hmap.key = Hmap.Key.create "comment_id"
  let react_to_comment : unit Hmap.key = Hmap.Key.create "react_to_comment"
  let encryption_key : Cstruct.t Hmap.key = Hmap.Key.create "encryption_key"

  let job_work_manifests :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Hmap.key =
    Hmap.Key.create "job_work_manifests"

  let work_manifest_id : Uuidm.t option Hmap.key = Hmap.Key.create "work_manifest_id"

  let work_manifest :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "work_manifest"

  let access_control : Access_control_engine.t Hmap.key = Hmap.Key.create "access_control"

  let access_control_eval_plan :
      (Terrat_access_control2.R.t, Terrat_access_control2.err) result Hmap.key =
    Hmap.Key.create "access_control_eval_plan"

  let access_control_eval_apply :
      (Terrat_access_control2.R.t, Terrat_access_control2.err) result Hmap.key =
    Hmap.Key.create "access_control_eval_apply"

  let check_access_control_ci_change : unit Hmap.key =
    Hmap.Key.create "check_access_control_ci_change"

  let check_access_control_files : unit Hmap.key = Hmap.Key.create "check_access_control_files"

  let check_access_control_repo_config : unit Hmap.key =
    Hmap.Key.create "check_access_control_repo_config"

  let check_valid_destination_branch : unit Hmap.key =
    Hmap.Key.create "check_valid_destination_branch"

  let check_access_control_plan : unit Hmap.key = Hmap.Key.create "check_access_control_plan"
  let check_account_status_expired : unit Hmap.key = Hmap.Key.create "check_account_status_expired"
  let check_account_tier : unit Hmap.key = Hmap.Key.create "check_account_tier"
  let check_merge_conflict : unit Hmap.key = Hmap.Key.create "check_merge_conflict"

  let check_conflicting_plan_work_manifests : unit Hmap.key =
    Hmap.Key.create "check_conflicting_plan_work_manifests"

  let check_pull_request_state : unit Hmap.key = Hmap.Key.create "check_pull_request_state"
  let publish_plan : unit Hmap.key = Hmap.Key.create "publish_plan"

  (* Context management *)
  let store_repository : unit Hmap.key = Hmap.Key.create "store_repository"
  let store_pull_request : unit Hmap.key = Hmap.Key.create "store_pull_request"
  let tag_query : Terrat_tag_query.t Hmap.key = Hmap.Key.create "tag_query"

  (* API facing targets *)

  let update_context_for_pull_request : unit Hmap.key =
    Hmap.Key.create "update_context_for_pull_request"

  let eval_compute_node_poll : Terrat_api_components.Work_manifest.t Hmap.key =
    Hmap.Key.create "eval_compute_node_poll"

  let eval_work_manifest_event : unit Hmap.key = Hmap.Key.create "eval_work_manifest_event"
  let eval_job : unit Hmap.key = Hmap.Key.create "eval_job"
end
