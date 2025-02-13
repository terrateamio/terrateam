type fetch_repo_config_with_provenance_err =
  [ Terrat_base_repo_config_v1.of_version_1_err
  | `Repo_config_parse_err of string * string
  | Jsonu.merge_err
  | `Json_decode_err of string * string
  | `Unexpected_err of string
  | `Yaml_decode_err of string * string
  | `Error
  ]
[@@deriving show]

type access_control_query_err = [ `Error ] [@@deriving show]
type access_control_err = access_control_query_err [@@deriving show]

module Unlock_id = struct
  type t =
    | Pull_request of int
    | Drift
  [@@deriving show]

  let to_string = function
    | Pull_request id -> CCInt.to_string id
    | Drift -> "drift"
end

module Account_status = struct
  type t =
    [ `Active
    | `Expired
    | `Disabled
    | `Trial_ending of Duration.t
    ]
end

module Target = struct
  type ('pr, 'repo) t =
    | Pr of 'pr
    | Drift of {
        repo : 'repo;
        branch : string;
      }
end

module Msg = struct
  type access_control_denied =
    [ `All_dirspaces of Terrat_access_control.R.Deny.t list
    | `Ci_config_update of Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Dirspaces of Terrat_access_control.R.Deny.t list
    | `Files of string * Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Lookup_err
    | `Terrateam_config_update of Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Unlock of Terrat_base_repo_config_v1.Access_control.Match_list.t
    ]

  type ('account, 'pull_request, 'target, 'apply_requirements) t =
    | Access_control_denied of (string * access_control_denied)
    | Account_expired
    | Apply_no_matching_dirspaces
    | Apply_requirements_config_err of [ Terrat_tag_query_ast.err | `Invalid_query of string ]
    | Apply_requirements_validation_err
    | Autoapply_running
    | Automerge_failure of ('pull_request * string)
    | Bad_custom_branch_tag_pattern of (string * string)
    | Bad_glob of string
    | Build_config_err of Terrat_base_repo_config_v1.of_version_1_err
    | Build_config_failure of string
    | Conflicting_work_manifests of ('account, 'target) Terrat_work_manifest3.Existing.t list
    | Depends_on_cycle of Terrat_dirspace.t list
    | Dest_branch_no_match of 'pull_request
    | Dirspaces_owned_by_other_pull_request of (Terrat_change.Dirspace.t * 'pull_request) list
    | Help
    | Index_complete of (bool * (string * int option * string) list)
    | Invalid_unlock_id of string
    | Maybe_stale_work_manifests of ('account, 'target) Terrat_work_manifest3.Existing.t list
    | Mismatched_refs
    | Missing_plans of Terrat_change.Dirspace.t list
    | Plan_no_matching_dirspaces
    | Premium_feature_err of [ `Access_control ]
    | Pull_request_not_appliable of ('pull_request * 'apply_requirements)
    | Pull_request_not_mergeable
    | Repo_config of (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t)
    | Repo_config_err of Terrat_base_repo_config_v1.of_version_1_err
    | Repo_config_failure of string
    | Repo_config_parse_failure of string * string
    | Run_work_manifest_err of [ `Failed_to_start | `Missing_workflow ]
    | Tag_query_err of Terrat_tag_query_ast.err
    | Tf_op_result of {
        is_layered_run : bool;
        remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
        result : Terrat_api_components_work_manifest_tf_operation_result.t;
        work_manifest : ('account, 'target) Terrat_work_manifest3.Existing.t;
      }
    | Tf_op_result2 of {
        account_status : Account_status.t;
        config : Terrat_config.t;
        is_layered_run : bool;
        remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
        result : Terrat_api_components_work_manifest_tf_operation_result2.t;
        work_manifest : ('account, 'target) Terrat_work_manifest3.Existing.t;
      }
    | Unexpected_temporary_err
    | Unlock_success
end

module type S = sig
  module Api : Terrat_vcs_api.S

  module Apply_requirements : sig
    type t

    val passed : t -> bool
    val approved_reviews : t -> Terrat_pull_request_review.t list
  end

  module Pull_request : sig
    type 'a t
  end

  module Comment : sig
    val publish_comment :
      request_id:string ->
      Api.Client.t ->
      Api.User.t ->
      'a Pull_request.t ->
      ( Api.Account.t,
        'a Pull_request.t,
        ('b Pull_request.t, Api.Repo.t) Target.t,
        Apply_requirements.t )
      Msg.t ->
      (unit, [> `Error ]) result Abb.Future.t
  end

  module Repo_config : sig
    val fetch_with_provenance :
      ?system_defaults:Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t ->
      ?built_config:Yojson.Safe.t ->
      string ->
      Api.Client.t ->
      Api.Repo.t ->
      Api.Ref.t ->
      ( string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
        [> fetch_repo_config_with_provenance_err ] )
      result
      Abb.Future.t
  end

  module Access_control : sig
    module Ctx : sig
      type t

      val make :
        client:Api.Client.t -> config:Terrat_config.t -> repo:Api.Repo.t -> user:string -> unit -> t
    end

    val query :
      Ctx.t ->
      Terrat_base_repo_config_v1.Access_control.Match.t ->
      (bool, [> access_control_query_err ]) result Abb.Future.t

    val is_ci_changed :
      Ctx.t -> Terrat_change.Diff.t list -> (bool, [> access_control_err ]) result Abb.Future.t

    val set_user : string -> Ctx.t -> Ctx.t
  end

  module Commit_check : sig
    val make_commit_check :
      ?work_manifest:('a, 'b) Terrat_work_manifest3.Existing.t ->
      config:Terrat_config.t ->
      description:string ->
      title:string ->
      status:Terrat_commit_check.Status.t ->
      repo:Api.Repo.t ->
      Api.Account.t ->
      Terrat_commit_check.t
  end

  module Ui : sig
    val work_manifest_url :
      Terrat_config.t -> Api.Account.t -> ('a, 'b) Terrat_work_manifest3.Existing.t -> Uri.t option
  end
end
