module Primary = struct
  module Analytics_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Auto_cancel_pending_pipelines = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Auto_devops_deploy_strategy = struct
    let t_of_yojson = function
      | `String "continuous" -> Ok "continuous"
      | `String "manual" -> Ok "manual"
      | `String "timed_incremental" -> Ok "timed_incremental"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Build_git_strategy = struct
    let t_of_yojson = function
      | `String "fetch" -> Ok "fetch"
      | `String "clone" -> Ok "clone"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Builds_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Ci_id_token_sub_claim_components = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Ci_pipeline_variables_minimum_override_role = struct
    let t_of_yojson = function
      | `String "no_one_allowed" -> Ok "no_one_allowed"
      | `String "developer" -> Ok "developer"
      | `String "maintainer" -> Ok "maintainer"
      | `String "owner" -> Ok "owner"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Container_expiration_policy_attributes = struct
    module Primary = struct
      type t = {
        cadence : string option; [@default None]
        enabled : bool option; [@default None]
        keep_n : int option; [@default None]
        name_regex : string option; [@default None]
        name_regex_keep : string option; [@default None]
        older_than : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Container_registry_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Environments_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Feature_flags_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Forking_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Infrastructure_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Issues_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Merge_method = struct
    let t_of_yojson = function
      | `String "ff" -> Ok "ff"
      | `String "rebase_merge" -> Ok "rebase_merge"
      | `String "merge" -> Ok "merge"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Merge_requests_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Model_experiments_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Model_registry_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Monitor_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pages_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | `String "public" -> Ok "public"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Releases_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Requirements_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Security_and_compliance_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Snippets_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Squash_option = struct
    let t_of_yojson = function
      | `String "never" -> Ok "never"
      | `String "always" -> Ok "always"
      | `String "default_on" -> Ok "default_on"
      | `String "default_off" -> Ok "default_off"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Tag_list = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Topics = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "private" -> Ok "private"
      | `String "internal" -> Ok "internal"
      | `String "public" -> Ok "public"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Wiki_access_level = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok "disabled"
      | `String "private" -> Ok "private"
      | `String "enabled" -> Ok "enabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allow_merge_on_skipped_pipeline : bool option; [@default None]
    allow_pipeline_trigger_approve_deployment : bool option; [@default None]
    analytics_access_level : Analytics_access_level.t option; [@default None]
    approvals_before_merge : int option; [@default None]
    auto_cancel_pending_pipelines : Auto_cancel_pending_pipelines.t option; [@default None]
    auto_devops_deploy_strategy : Auto_devops_deploy_strategy.t option; [@default None]
    auto_devops_enabled : bool option; [@default None]
    autoclose_referenced_issues : bool option; [@default None]
    avatar : string option; [@default None]
    build_git_strategy : Build_git_strategy.t option; [@default None]
    build_timeout : int option; [@default None]
    builds_access_level : Builds_access_level.t option; [@default None]
    ci_allow_fork_pipelines_to_run_in_parent_project : bool option; [@default None]
    ci_config_path : string option; [@default None]
    ci_default_git_depth : int option; [@default None]
    ci_delete_pipelines_in_seconds : int option; [@default None]
    ci_forward_deployment_enabled : bool option; [@default None]
    ci_forward_deployment_rollback_allowed : bool option; [@default None]
    ci_id_token_sub_claim_components : Ci_id_token_sub_claim_components.t option; [@default None]
    ci_pipeline_variables_minimum_override_role :
      Ci_pipeline_variables_minimum_override_role.t option;
        [@default None]
    ci_push_repository_for_job_token_allowed : bool option; [@default None]
    ci_restrict_pipeline_cancellation_role : string option; [@default None]
    ci_separated_caches : bool option; [@default None]
    container_expiration_policy_attributes : Container_expiration_policy_attributes.t option;
        [@default None]
    container_registry_access_level : Container_registry_access_level.t option; [@default None]
    container_registry_enabled : bool option; [@default None]
    default_branch : string option; [@default None]
    description : string option; [@default None]
    emails_disabled : bool option; [@default None]
    emails_enabled : bool option; [@default None]
    enforce_auth_checks_on_uploads : bool option; [@default None]
    environments_access_level : Environments_access_level.t option; [@default None]
    external_authorization_classification_label : string option; [@default None]
    fallback_approvals_required : int option; [@default None]
    feature_flags_access_level : Feature_flags_access_level.t option; [@default None]
    forking_access_level : Forking_access_level.t option; [@default None]
    group_runners_enabled : bool option; [@default None]
    import_url : string option; [@default None]
    infrastructure_access_level : Infrastructure_access_level.t option; [@default None]
    issue_branch_template : string option; [@default None]
    issues_access_level : Issues_access_level.t option; [@default None]
    issues_enabled : bool option; [@default None]
    issues_template : string option; [@default None]
    jobs_enabled : bool option; [@default None]
    keep_latest_artifact : bool option; [@default None]
    lfs_enabled : bool option; [@default None]
    max_artifacts_size : int option; [@default None]
    merge_commit_template : string option; [@default None]
    merge_method : Merge_method.t option; [@default None]
    merge_pipelines_enabled : bool option; [@default None]
    merge_requests_access_level : Merge_requests_access_level.t option; [@default None]
    merge_requests_enabled : bool option; [@default None]
    merge_requests_template : string option; [@default None]
    merge_trains_enabled : bool option; [@default None]
    merge_trains_skip_train_allowed : bool option; [@default None]
    mirror : bool option; [@default None]
    mirror_branch_regex : string option; [@default None]
    mirror_overwrites_diverged_branches : bool option; [@default None]
    mirror_trigger_builds : bool option; [@default None]
    mirror_user_id : int option; [@default None]
    model_experiments_access_level : Model_experiments_access_level.t option; [@default None]
    model_registry_access_level : Model_registry_access_level.t option; [@default None]
    monitor_access_level : Monitor_access_level.t option; [@default None]
    mr_default_target_self : bool option; [@default None]
    name : string option; [@default None]
    only_allow_merge_if_all_discussions_are_resolved : bool option; [@default None]
    only_allow_merge_if_all_status_checks_passed : bool option; [@default None]
    only_allow_merge_if_pipeline_succeeds : bool option; [@default None]
    only_mirror_protected_branches : bool option; [@default None]
    packages_enabled : bool option; [@default None]
    pages_access_level : Pages_access_level.t option; [@default None]
    path : string option; [@default None]
    prevent_merge_without_jira_issue : bool option; [@default None]
    printing_merge_request_link_enabled : bool option; [@default None]
    public_builds : bool option; [@default None]
    public_jobs : bool option; [@default None]
    releases_access_level : Releases_access_level.t option; [@default None]
    remove_source_branch_after_merge : bool option; [@default None]
    repository_access_level : Repository_access_level.t option; [@default None]
    repository_storage : string option; [@default None]
    request_access_enabled : bool option; [@default None]
    requirements_access_level : Requirements_access_level.t option; [@default None]
    resolve_outdated_diff_discussions : bool option; [@default None]
    restrict_user_defined_variables : bool option; [@default None]
    security_and_compliance_access_level : Security_and_compliance_access_level.t option;
        [@default None]
    service_desk_enabled : bool option; [@default None]
    shared_runners_enabled : bool option; [@default None]
    show_default_award_emojis : bool option; [@default None]
    show_diff_preview_in_email : bool option; [@default None]
    snippets_access_level : Snippets_access_level.t option; [@default None]
    snippets_enabled : bool option; [@default None]
    squash_commit_template : string option; [@default None]
    squash_option : Squash_option.t option; [@default None]
    suggestion_commit_message : string option; [@default None]
    tag_list : Tag_list.t option; [@default None]
    topics : Topics.t option; [@default None]
    visibility : Visibility.t option; [@default None]
    warn_about_potentially_unwanted_characters : bool option; [@default None]
    wiki_access_level : Wiki_access_level.t option; [@default None]
    wiki_enabled : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
