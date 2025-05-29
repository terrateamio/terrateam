module PostApiV4ProjectsImport = struct
  module Parameters = struct
    module Override_params_analytics_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_cancel_pending_pipelines_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_devops_deploy_strategy_ = struct
      let t_of_yojson = function
        | `String "continuous" -> Ok "continuous"
        | `String "manual" -> Ok "manual"
        | `String "timed_incremental" -> Ok "timed_incremental"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_build_git_strategy_ = struct
      let t_of_yojson = function
        | `String "fetch" -> Ok "fetch"
        | `String "clone" -> Ok "clone"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_builds_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_container_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_environments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_feature_flags_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_forking_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_infrastructure_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_issues_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_method_ = struct
      let t_of_yojson = function
        | `String "ff" -> Ok "ff"
        | `String "rebase_merge" -> Ok "rebase_merge"
        | `String "merge" -> Ok "merge"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_requests_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_experiments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_monitor_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_pages_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_releases_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_repository_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_requirements_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_security_and_compliance_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_snippets_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_squash_option_ = struct
      let t_of_yojson = function
        | `String "never" -> Ok "never"
        | `String "always" -> Ok "always"
        | `String "default_on" -> Ok "default_on"
        | `String "default_off" -> Ok "default_off"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_tag_list_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_topics_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_visibility_ = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_wiki_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      file : string;
      file_etag : string option; [@default None] [@key "file.etag"]
      file_md5 : string option; [@default None] [@key "file.md5"]
      file_name : string option; [@default None] [@key "file.name"]
      file_path : string option; [@default None] [@key "file.path"]
      file_remote_id : string option; [@default None] [@key "file.remote_id"]
      file_remote_url : string option; [@default None] [@key "file.remote_url"]
      file_sha1 : string option; [@default None] [@key "file.sha1"]
      file_sha256 : string option; [@default None] [@key "file.sha256"]
      file_size : int option; [@default None] [@key "file.size"]
      file_type : string option; [@default None] [@key "file.type"]
      name : string option; [@default None]
      namespace : string option; [@default None]
      override_params_allow_merge_on_skipped_pipeline_ : bool option;
          [@default None] [@key "override_params[allow_merge_on_skipped_pipeline]"]
      override_params_analytics_access_level_ : Override_params_analytics_access_level_.t option;
          [@default None] [@key "override_params[analytics_access_level]"]
      override_params_approvals_before_merge_ : int option;
          [@default None] [@key "override_params[approvals_before_merge]"]
      override_params_auto_cancel_pending_pipelines_ :
        Override_params_auto_cancel_pending_pipelines_.t option;
          [@default None] [@key "override_params[auto_cancel_pending_pipelines]"]
      override_params_auto_devops_deploy_strategy_ :
        Override_params_auto_devops_deploy_strategy_.t option;
          [@default None] [@key "override_params[auto_devops_deploy_strategy]"]
      override_params_auto_devops_enabled_ : bool option;
          [@default None] [@key "override_params[auto_devops_enabled]"]
      override_params_autoclose_referenced_issues_ : bool option;
          [@default None] [@key "override_params[autoclose_referenced_issues]"]
      override_params_avatar_ : string option; [@default None] [@key "override_params[avatar]"]
      override_params_build_git_strategy_ : Override_params_build_git_strategy_.t option;
          [@default None] [@key "override_params[build_git_strategy]"]
      override_params_build_timeout_ : int option;
          [@default None] [@key "override_params[build_timeout]"]
      override_params_builds_access_level_ : Override_params_builds_access_level_.t option;
          [@default None] [@key "override_params[builds_access_level]"]
      override_params_ci_config_path_ : string option;
          [@default None] [@key "override_params[ci_config_path]"]
      override_params_container_expiration_policy_attributes__cadence_ : string option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][cadence]"]
      override_params_container_expiration_policy_attributes__enabled_ : bool option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][enabled]"]
      override_params_container_expiration_policy_attributes__keep_n_ : int option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][keep_n]"]
      override_params_container_expiration_policy_attributes__name_regex_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex]"]
      override_params_container_expiration_policy_attributes__name_regex_keep_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex_keep]"]
      override_params_container_expiration_policy_attributes__older_than_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][older_than]"]
      override_params_container_registry_access_level_ :
        Override_params_container_registry_access_level_.t option;
          [@default None] [@key "override_params[container_registry_access_level]"]
      override_params_container_registry_enabled_ : bool option;
          [@default None] [@key "override_params[container_registry_enabled]"]
      override_params_description_ : string option;
          [@default None] [@key "override_params[description]"]
      override_params_emails_disabled_ : bool option;
          [@default None] [@key "override_params[emails_disabled]"]
      override_params_emails_enabled_ : bool option;
          [@default None] [@key "override_params[emails_enabled]"]
      override_params_enforce_auth_checks_on_uploads_ : bool option;
          [@default None] [@key "override_params[enforce_auth_checks_on_uploads]"]
      override_params_environments_access_level_ :
        Override_params_environments_access_level_.t option;
          [@default None] [@key "override_params[environments_access_level]"]
      override_params_external_authorization_classification_label_ : string option;
          [@default None] [@key "override_params[external_authorization_classification_label]"]
      override_params_feature_flags_access_level_ :
        Override_params_feature_flags_access_level_.t option;
          [@default None] [@key "override_params[feature_flags_access_level]"]
      override_params_forking_access_level_ : Override_params_forking_access_level_.t option;
          [@default None] [@key "override_params[forking_access_level]"]
      override_params_group_runners_enabled_ : bool option;
          [@default None] [@key "override_params[group_runners_enabled]"]
      override_params_infrastructure_access_level_ :
        Override_params_infrastructure_access_level_.t option;
          [@default None] [@key "override_params[infrastructure_access_level]"]
      override_params_issue_branch_template_ : string option;
          [@default None] [@key "override_params[issue_branch_template]"]
      override_params_issues_access_level_ : Override_params_issues_access_level_.t option;
          [@default None] [@key "override_params[issues_access_level]"]
      override_params_issues_enabled_ : bool option;
          [@default None] [@key "override_params[issues_enabled]"]
      override_params_jobs_enabled_ : bool option;
          [@default None] [@key "override_params[jobs_enabled]"]
      override_params_lfs_enabled_ : bool option;
          [@default None] [@key "override_params[lfs_enabled]"]
      override_params_merge_commit_template_ : string option;
          [@default None] [@key "override_params[merge_commit_template]"]
      override_params_merge_method_ : Override_params_merge_method_.t option;
          [@default None] [@key "override_params[merge_method]"]
      override_params_merge_requests_access_level_ :
        Override_params_merge_requests_access_level_.t option;
          [@default None] [@key "override_params[merge_requests_access_level]"]
      override_params_merge_requests_enabled_ : bool option;
          [@default None] [@key "override_params[merge_requests_enabled]"]
      override_params_mirror_ : bool option; [@default None] [@key "override_params[mirror]"]
      override_params_mirror_trigger_builds_ : bool option;
          [@default None] [@key "override_params[mirror_trigger_builds]"]
      override_params_model_experiments_access_level_ :
        Override_params_model_experiments_access_level_.t option;
          [@default None] [@key "override_params[model_experiments_access_level]"]
      override_params_model_registry_access_level_ :
        Override_params_model_registry_access_level_.t option;
          [@default None] [@key "override_params[model_registry_access_level]"]
      override_params_monitor_access_level_ : Override_params_monitor_access_level_.t option;
          [@default None] [@key "override_params[monitor_access_level]"]
      override_params_mr_default_target_self_ : bool option;
          [@default None] [@key "override_params[mr_default_target_self]"]
      override_params_only_allow_merge_if_all_discussions_are_resolved_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_discussions_are_resolved]"]
      override_params_only_allow_merge_if_all_status_checks_passed_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_status_checks_passed]"]
      override_params_only_allow_merge_if_pipeline_succeeds_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_pipeline_succeeds]"]
      override_params_packages_enabled_ : bool option;
          [@default None] [@key "override_params[packages_enabled]"]
      override_params_pages_access_level_ : Override_params_pages_access_level_.t option;
          [@default None] [@key "override_params[pages_access_level]"]
      override_params_prevent_merge_without_jira_issue_ : bool option;
          [@default None] [@key "override_params[prevent_merge_without_jira_issue]"]
      override_params_printing_merge_request_link_enabled_ : bool option;
          [@default None] [@key "override_params[printing_merge_request_link_enabled]"]
      override_params_public_builds_ : bool option;
          [@default None] [@key "override_params[public_builds]"]
      override_params_public_jobs_ : bool option;
          [@default None] [@key "override_params[public_jobs]"]
      override_params_releases_access_level_ : Override_params_releases_access_level_.t option;
          [@default None] [@key "override_params[releases_access_level]"]
      override_params_remove_source_branch_after_merge_ : bool option;
          [@default None] [@key "override_params[remove_source_branch_after_merge]"]
      override_params_repository_access_level_ : Override_params_repository_access_level_.t option;
          [@default None] [@key "override_params[repository_access_level]"]
      override_params_repository_storage_ : string option;
          [@default None] [@key "override_params[repository_storage]"]
      override_params_request_access_enabled_ : bool option;
          [@default None] [@key "override_params[request_access_enabled]"]
      override_params_requirements_access_level_ :
        Override_params_requirements_access_level_.t option;
          [@default None] [@key "override_params[requirements_access_level]"]
      override_params_resolve_outdated_diff_discussions_ : bool option;
          [@default None] [@key "override_params[resolve_outdated_diff_discussions]"]
      override_params_security_and_compliance_access_level_ :
        Override_params_security_and_compliance_access_level_.t option;
          [@default None] [@key "override_params[security_and_compliance_access_level]"]
      override_params_service_desk_enabled_ : bool option;
          [@default None] [@key "override_params[service_desk_enabled]"]
      override_params_shared_runners_enabled_ : bool option;
          [@default None] [@key "override_params[shared_runners_enabled]"]
      override_params_show_default_award_emojis_ : bool option;
          [@default None] [@key "override_params[show_default_award_emojis]"]
      override_params_show_diff_preview_in_email_ : bool option;
          [@default None] [@key "override_params[show_diff_preview_in_email]"]
      override_params_snippets_access_level_ : Override_params_snippets_access_level_.t option;
          [@default None] [@key "override_params[snippets_access_level]"]
      override_params_snippets_enabled_ : bool option;
          [@default None] [@key "override_params[snippets_enabled]"]
      override_params_squash_commit_template_ : string option;
          [@default None] [@key "override_params[squash_commit_template]"]
      override_params_squash_option_ : Override_params_squash_option_.t option;
          [@default None] [@key "override_params[squash_option]"]
      override_params_suggestion_commit_message_ : string option;
          [@default None] [@key "override_params[suggestion_commit_message]"]
      override_params_tag_list_ : Override_params_tag_list_.t option;
          [@default None] [@key "override_params[tag_list]"]
      override_params_topics_ : Override_params_topics_.t option;
          [@default None] [@key "override_params[topics]"]
      override_params_visibility_ : Override_params_visibility_.t option;
          [@default None] [@key "override_params[visibility]"]
      override_params_warn_about_potentially_unwanted_characters_ : bool option;
          [@default None] [@key "override_params[warn_about_potentially_unwanted_characters]"]
      override_params_wiki_access_level_ : Override_params_wiki_access_level_.t option;
          [@default None] [@key "override_params[wiki_access_level]"]
      override_params_wiki_enabled_ : bool option;
          [@default None] [@key "override_params[wiki_enabled]"]
      overwrite : bool; [@default false]
      path : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/import"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsImportRelation = struct
  module Parameters = struct
    type t = {
      file : string;
      file_etag : string option; [@default None] [@key "file.etag"]
      file_md5 : string option; [@default None] [@key "file.md5"]
      file_name : string option; [@default None] [@key "file.name"]
      file_path : string option; [@default None] [@key "file.path"]
      file_remote_id : string option; [@default None] [@key "file.remote_id"]
      file_remote_url : string option; [@default None] [@key "file.remote_url"]
      file_sha1 : string option; [@default None] [@key "file.sha1"]
      file_sha256 : string option; [@default None] [@key "file.sha256"]
      file_size : int option; [@default None] [@key "file.size"]
      file_type : string option; [@default None] [@key "file.type"]
      path : string;
      relation : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/import-relation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsImportRelationAuthorize = struct
  module Parameters = struct end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/import-relation/authorize"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsImportAuthorize = struct
  module Parameters = struct end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/import/authorize"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsRemoteImport = struct
  module Parameters = struct
    module Override_params_analytics_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_cancel_pending_pipelines_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_devops_deploy_strategy_ = struct
      let t_of_yojson = function
        | `String "continuous" -> Ok "continuous"
        | `String "manual" -> Ok "manual"
        | `String "timed_incremental" -> Ok "timed_incremental"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_build_git_strategy_ = struct
      let t_of_yojson = function
        | `String "fetch" -> Ok "fetch"
        | `String "clone" -> Ok "clone"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_builds_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_container_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_environments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_feature_flags_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_forking_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_infrastructure_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_issues_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_method_ = struct
      let t_of_yojson = function
        | `String "ff" -> Ok "ff"
        | `String "rebase_merge" -> Ok "rebase_merge"
        | `String "merge" -> Ok "merge"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_requests_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_experiments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_monitor_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_pages_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_releases_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_repository_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_requirements_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_security_and_compliance_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_snippets_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_squash_option_ = struct
      let t_of_yojson = function
        | `String "never" -> Ok "never"
        | `String "always" -> Ok "always"
        | `String "default_on" -> Ok "default_on"
        | `String "default_off" -> Ok "default_off"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_tag_list_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_topics_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_visibility_ = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_wiki_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      name : string option; [@default None]
      namespace : string option; [@default None]
      override_params_allow_merge_on_skipped_pipeline_ : bool option;
          [@default None] [@key "override_params[allow_merge_on_skipped_pipeline]"]
      override_params_analytics_access_level_ : Override_params_analytics_access_level_.t option;
          [@default None] [@key "override_params[analytics_access_level]"]
      override_params_approvals_before_merge_ : int option;
          [@default None] [@key "override_params[approvals_before_merge]"]
      override_params_auto_cancel_pending_pipelines_ :
        Override_params_auto_cancel_pending_pipelines_.t option;
          [@default None] [@key "override_params[auto_cancel_pending_pipelines]"]
      override_params_auto_devops_deploy_strategy_ :
        Override_params_auto_devops_deploy_strategy_.t option;
          [@default None] [@key "override_params[auto_devops_deploy_strategy]"]
      override_params_auto_devops_enabled_ : bool option;
          [@default None] [@key "override_params[auto_devops_enabled]"]
      override_params_autoclose_referenced_issues_ : bool option;
          [@default None] [@key "override_params[autoclose_referenced_issues]"]
      override_params_avatar_ : string option; [@default None] [@key "override_params[avatar]"]
      override_params_build_git_strategy_ : Override_params_build_git_strategy_.t option;
          [@default None] [@key "override_params[build_git_strategy]"]
      override_params_build_timeout_ : int option;
          [@default None] [@key "override_params[build_timeout]"]
      override_params_builds_access_level_ : Override_params_builds_access_level_.t option;
          [@default None] [@key "override_params[builds_access_level]"]
      override_params_ci_config_path_ : string option;
          [@default None] [@key "override_params[ci_config_path]"]
      override_params_container_expiration_policy_attributes__cadence_ : string option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][cadence]"]
      override_params_container_expiration_policy_attributes__enabled_ : bool option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][enabled]"]
      override_params_container_expiration_policy_attributes__keep_n_ : int option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][keep_n]"]
      override_params_container_expiration_policy_attributes__name_regex_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex]"]
      override_params_container_expiration_policy_attributes__name_regex_keep_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex_keep]"]
      override_params_container_expiration_policy_attributes__older_than_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][older_than]"]
      override_params_container_registry_access_level_ :
        Override_params_container_registry_access_level_.t option;
          [@default None] [@key "override_params[container_registry_access_level]"]
      override_params_container_registry_enabled_ : bool option;
          [@default None] [@key "override_params[container_registry_enabled]"]
      override_params_description_ : string option;
          [@default None] [@key "override_params[description]"]
      override_params_emails_disabled_ : bool option;
          [@default None] [@key "override_params[emails_disabled]"]
      override_params_emails_enabled_ : bool option;
          [@default None] [@key "override_params[emails_enabled]"]
      override_params_enforce_auth_checks_on_uploads_ : bool option;
          [@default None] [@key "override_params[enforce_auth_checks_on_uploads]"]
      override_params_environments_access_level_ :
        Override_params_environments_access_level_.t option;
          [@default None] [@key "override_params[environments_access_level]"]
      override_params_external_authorization_classification_label_ : string option;
          [@default None] [@key "override_params[external_authorization_classification_label]"]
      override_params_feature_flags_access_level_ :
        Override_params_feature_flags_access_level_.t option;
          [@default None] [@key "override_params[feature_flags_access_level]"]
      override_params_forking_access_level_ : Override_params_forking_access_level_.t option;
          [@default None] [@key "override_params[forking_access_level]"]
      override_params_group_runners_enabled_ : bool option;
          [@default None] [@key "override_params[group_runners_enabled]"]
      override_params_infrastructure_access_level_ :
        Override_params_infrastructure_access_level_.t option;
          [@default None] [@key "override_params[infrastructure_access_level]"]
      override_params_issue_branch_template_ : string option;
          [@default None] [@key "override_params[issue_branch_template]"]
      override_params_issues_access_level_ : Override_params_issues_access_level_.t option;
          [@default None] [@key "override_params[issues_access_level]"]
      override_params_issues_enabled_ : bool option;
          [@default None] [@key "override_params[issues_enabled]"]
      override_params_jobs_enabled_ : bool option;
          [@default None] [@key "override_params[jobs_enabled]"]
      override_params_lfs_enabled_ : bool option;
          [@default None] [@key "override_params[lfs_enabled]"]
      override_params_merge_commit_template_ : string option;
          [@default None] [@key "override_params[merge_commit_template]"]
      override_params_merge_method_ : Override_params_merge_method_.t option;
          [@default None] [@key "override_params[merge_method]"]
      override_params_merge_requests_access_level_ :
        Override_params_merge_requests_access_level_.t option;
          [@default None] [@key "override_params[merge_requests_access_level]"]
      override_params_merge_requests_enabled_ : bool option;
          [@default None] [@key "override_params[merge_requests_enabled]"]
      override_params_mirror_ : bool option; [@default None] [@key "override_params[mirror]"]
      override_params_mirror_trigger_builds_ : bool option;
          [@default None] [@key "override_params[mirror_trigger_builds]"]
      override_params_model_experiments_access_level_ :
        Override_params_model_experiments_access_level_.t option;
          [@default None] [@key "override_params[model_experiments_access_level]"]
      override_params_model_registry_access_level_ :
        Override_params_model_registry_access_level_.t option;
          [@default None] [@key "override_params[model_registry_access_level]"]
      override_params_monitor_access_level_ : Override_params_monitor_access_level_.t option;
          [@default None] [@key "override_params[monitor_access_level]"]
      override_params_mr_default_target_self_ : bool option;
          [@default None] [@key "override_params[mr_default_target_self]"]
      override_params_only_allow_merge_if_all_discussions_are_resolved_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_discussions_are_resolved]"]
      override_params_only_allow_merge_if_all_status_checks_passed_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_status_checks_passed]"]
      override_params_only_allow_merge_if_pipeline_succeeds_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_pipeline_succeeds]"]
      override_params_packages_enabled_ : bool option;
          [@default None] [@key "override_params[packages_enabled]"]
      override_params_pages_access_level_ : Override_params_pages_access_level_.t option;
          [@default None] [@key "override_params[pages_access_level]"]
      override_params_prevent_merge_without_jira_issue_ : bool option;
          [@default None] [@key "override_params[prevent_merge_without_jira_issue]"]
      override_params_printing_merge_request_link_enabled_ : bool option;
          [@default None] [@key "override_params[printing_merge_request_link_enabled]"]
      override_params_public_builds_ : bool option;
          [@default None] [@key "override_params[public_builds]"]
      override_params_public_jobs_ : bool option;
          [@default None] [@key "override_params[public_jobs]"]
      override_params_releases_access_level_ : Override_params_releases_access_level_.t option;
          [@default None] [@key "override_params[releases_access_level]"]
      override_params_remove_source_branch_after_merge_ : bool option;
          [@default None] [@key "override_params[remove_source_branch_after_merge]"]
      override_params_repository_access_level_ : Override_params_repository_access_level_.t option;
          [@default None] [@key "override_params[repository_access_level]"]
      override_params_repository_storage_ : string option;
          [@default None] [@key "override_params[repository_storage]"]
      override_params_request_access_enabled_ : bool option;
          [@default None] [@key "override_params[request_access_enabled]"]
      override_params_requirements_access_level_ :
        Override_params_requirements_access_level_.t option;
          [@default None] [@key "override_params[requirements_access_level]"]
      override_params_resolve_outdated_diff_discussions_ : bool option;
          [@default None] [@key "override_params[resolve_outdated_diff_discussions]"]
      override_params_security_and_compliance_access_level_ :
        Override_params_security_and_compliance_access_level_.t option;
          [@default None] [@key "override_params[security_and_compliance_access_level]"]
      override_params_service_desk_enabled_ : bool option;
          [@default None] [@key "override_params[service_desk_enabled]"]
      override_params_shared_runners_enabled_ : bool option;
          [@default None] [@key "override_params[shared_runners_enabled]"]
      override_params_show_default_award_emojis_ : bool option;
          [@default None] [@key "override_params[show_default_award_emojis]"]
      override_params_show_diff_preview_in_email_ : bool option;
          [@default None] [@key "override_params[show_diff_preview_in_email]"]
      override_params_snippets_access_level_ : Override_params_snippets_access_level_.t option;
          [@default None] [@key "override_params[snippets_access_level]"]
      override_params_snippets_enabled_ : bool option;
          [@default None] [@key "override_params[snippets_enabled]"]
      override_params_squash_commit_template_ : string option;
          [@default None] [@key "override_params[squash_commit_template]"]
      override_params_squash_option_ : Override_params_squash_option_.t option;
          [@default None] [@key "override_params[squash_option]"]
      override_params_suggestion_commit_message_ : string option;
          [@default None] [@key "override_params[suggestion_commit_message]"]
      override_params_tag_list_ : Override_params_tag_list_.t option;
          [@default None] [@key "override_params[tag_list]"]
      override_params_topics_ : Override_params_topics_.t option;
          [@default None] [@key "override_params[topics]"]
      override_params_visibility_ : Override_params_visibility_.t option;
          [@default None] [@key "override_params[visibility]"]
      override_params_warn_about_potentially_unwanted_characters_ : bool option;
          [@default None] [@key "override_params[warn_about_potentially_unwanted_characters]"]
      override_params_wiki_access_level_ : Override_params_wiki_access_level_.t option;
          [@default None] [@key "override_params[wiki_access_level]"]
      override_params_wiki_enabled_ : bool option;
          [@default None] [@key "override_params[wiki_enabled]"]
      overwrite : bool; [@default false]
      path : string;
      url : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Too_many_requests = struct end
    module Service_unavailable = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Too_many_requests
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("429", fun _ -> Ok `Too_many_requests);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/remote-import"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsRemoteImportS3 = struct
  module Parameters = struct
    module Override_params_analytics_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_cancel_pending_pipelines_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_auto_devops_deploy_strategy_ = struct
      let t_of_yojson = function
        | `String "continuous" -> Ok "continuous"
        | `String "manual" -> Ok "manual"
        | `String "timed_incremental" -> Ok "timed_incremental"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_build_git_strategy_ = struct
      let t_of_yojson = function
        | `String "fetch" -> Ok "fetch"
        | `String "clone" -> Ok "clone"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_builds_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_container_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_environments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_feature_flags_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_forking_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_infrastructure_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_issues_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_method_ = struct
      let t_of_yojson = function
        | `String "ff" -> Ok "ff"
        | `String "rebase_merge" -> Ok "rebase_merge"
        | `String "merge" -> Ok "merge"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_merge_requests_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_experiments_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_model_registry_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_monitor_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_pages_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_releases_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_repository_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_requirements_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_security_and_compliance_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_snippets_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_squash_option_ = struct
      let t_of_yojson = function
        | `String "never" -> Ok "never"
        | `String "always" -> Ok "always"
        | `String "default_on" -> Ok "default_on"
        | `String "default_off" -> Ok "default_off"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_tag_list_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_topics_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Override_params_visibility_ = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Override_params_wiki_access_level_ = struct
      let t_of_yojson = function
        | `String "disabled" -> Ok "disabled"
        | `String "private" -> Ok "private"
        | `String "enabled" -> Ok "enabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      access_key_id : string;
      bucket_name : string;
      file_key : string;
      name : string option; [@default None]
      namespace : string option; [@default None]
      override_params_allow_merge_on_skipped_pipeline_ : bool option;
          [@default None] [@key "override_params[allow_merge_on_skipped_pipeline]"]
      override_params_analytics_access_level_ : Override_params_analytics_access_level_.t option;
          [@default None] [@key "override_params[analytics_access_level]"]
      override_params_approvals_before_merge_ : int option;
          [@default None] [@key "override_params[approvals_before_merge]"]
      override_params_auto_cancel_pending_pipelines_ :
        Override_params_auto_cancel_pending_pipelines_.t option;
          [@default None] [@key "override_params[auto_cancel_pending_pipelines]"]
      override_params_auto_devops_deploy_strategy_ :
        Override_params_auto_devops_deploy_strategy_.t option;
          [@default None] [@key "override_params[auto_devops_deploy_strategy]"]
      override_params_auto_devops_enabled_ : bool option;
          [@default None] [@key "override_params[auto_devops_enabled]"]
      override_params_autoclose_referenced_issues_ : bool option;
          [@default None] [@key "override_params[autoclose_referenced_issues]"]
      override_params_avatar_ : string option; [@default None] [@key "override_params[avatar]"]
      override_params_build_git_strategy_ : Override_params_build_git_strategy_.t option;
          [@default None] [@key "override_params[build_git_strategy]"]
      override_params_build_timeout_ : int option;
          [@default None] [@key "override_params[build_timeout]"]
      override_params_builds_access_level_ : Override_params_builds_access_level_.t option;
          [@default None] [@key "override_params[builds_access_level]"]
      override_params_ci_config_path_ : string option;
          [@default None] [@key "override_params[ci_config_path]"]
      override_params_container_expiration_policy_attributes__cadence_ : string option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][cadence]"]
      override_params_container_expiration_policy_attributes__enabled_ : bool option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][enabled]"]
      override_params_container_expiration_policy_attributes__keep_n_ : int option;
          [@default None] [@key "override_params[container_expiration_policy_attributes][keep_n]"]
      override_params_container_expiration_policy_attributes__name_regex_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex]"]
      override_params_container_expiration_policy_attributes__name_regex_keep_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][name_regex_keep]"]
      override_params_container_expiration_policy_attributes__older_than_ : string option;
          [@default None]
          [@key "override_params[container_expiration_policy_attributes][older_than]"]
      override_params_container_registry_access_level_ :
        Override_params_container_registry_access_level_.t option;
          [@default None] [@key "override_params[container_registry_access_level]"]
      override_params_container_registry_enabled_ : bool option;
          [@default None] [@key "override_params[container_registry_enabled]"]
      override_params_description_ : string option;
          [@default None] [@key "override_params[description]"]
      override_params_emails_disabled_ : bool option;
          [@default None] [@key "override_params[emails_disabled]"]
      override_params_emails_enabled_ : bool option;
          [@default None] [@key "override_params[emails_enabled]"]
      override_params_enforce_auth_checks_on_uploads_ : bool option;
          [@default None] [@key "override_params[enforce_auth_checks_on_uploads]"]
      override_params_environments_access_level_ :
        Override_params_environments_access_level_.t option;
          [@default None] [@key "override_params[environments_access_level]"]
      override_params_external_authorization_classification_label_ : string option;
          [@default None] [@key "override_params[external_authorization_classification_label]"]
      override_params_feature_flags_access_level_ :
        Override_params_feature_flags_access_level_.t option;
          [@default None] [@key "override_params[feature_flags_access_level]"]
      override_params_forking_access_level_ : Override_params_forking_access_level_.t option;
          [@default None] [@key "override_params[forking_access_level]"]
      override_params_group_runners_enabled_ : bool option;
          [@default None] [@key "override_params[group_runners_enabled]"]
      override_params_infrastructure_access_level_ :
        Override_params_infrastructure_access_level_.t option;
          [@default None] [@key "override_params[infrastructure_access_level]"]
      override_params_issue_branch_template_ : string option;
          [@default None] [@key "override_params[issue_branch_template]"]
      override_params_issues_access_level_ : Override_params_issues_access_level_.t option;
          [@default None] [@key "override_params[issues_access_level]"]
      override_params_issues_enabled_ : bool option;
          [@default None] [@key "override_params[issues_enabled]"]
      override_params_jobs_enabled_ : bool option;
          [@default None] [@key "override_params[jobs_enabled]"]
      override_params_lfs_enabled_ : bool option;
          [@default None] [@key "override_params[lfs_enabled]"]
      override_params_merge_commit_template_ : string option;
          [@default None] [@key "override_params[merge_commit_template]"]
      override_params_merge_method_ : Override_params_merge_method_.t option;
          [@default None] [@key "override_params[merge_method]"]
      override_params_merge_requests_access_level_ :
        Override_params_merge_requests_access_level_.t option;
          [@default None] [@key "override_params[merge_requests_access_level]"]
      override_params_merge_requests_enabled_ : bool option;
          [@default None] [@key "override_params[merge_requests_enabled]"]
      override_params_mirror_ : bool option; [@default None] [@key "override_params[mirror]"]
      override_params_mirror_trigger_builds_ : bool option;
          [@default None] [@key "override_params[mirror_trigger_builds]"]
      override_params_model_experiments_access_level_ :
        Override_params_model_experiments_access_level_.t option;
          [@default None] [@key "override_params[model_experiments_access_level]"]
      override_params_model_registry_access_level_ :
        Override_params_model_registry_access_level_.t option;
          [@default None] [@key "override_params[model_registry_access_level]"]
      override_params_monitor_access_level_ : Override_params_monitor_access_level_.t option;
          [@default None] [@key "override_params[monitor_access_level]"]
      override_params_mr_default_target_self_ : bool option;
          [@default None] [@key "override_params[mr_default_target_self]"]
      override_params_only_allow_merge_if_all_discussions_are_resolved_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_discussions_are_resolved]"]
      override_params_only_allow_merge_if_all_status_checks_passed_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_all_status_checks_passed]"]
      override_params_only_allow_merge_if_pipeline_succeeds_ : bool option;
          [@default None] [@key "override_params[only_allow_merge_if_pipeline_succeeds]"]
      override_params_packages_enabled_ : bool option;
          [@default None] [@key "override_params[packages_enabled]"]
      override_params_pages_access_level_ : Override_params_pages_access_level_.t option;
          [@default None] [@key "override_params[pages_access_level]"]
      override_params_prevent_merge_without_jira_issue_ : bool option;
          [@default None] [@key "override_params[prevent_merge_without_jira_issue]"]
      override_params_printing_merge_request_link_enabled_ : bool option;
          [@default None] [@key "override_params[printing_merge_request_link_enabled]"]
      override_params_public_builds_ : bool option;
          [@default None] [@key "override_params[public_builds]"]
      override_params_public_jobs_ : bool option;
          [@default None] [@key "override_params[public_jobs]"]
      override_params_releases_access_level_ : Override_params_releases_access_level_.t option;
          [@default None] [@key "override_params[releases_access_level]"]
      override_params_remove_source_branch_after_merge_ : bool option;
          [@default None] [@key "override_params[remove_source_branch_after_merge]"]
      override_params_repository_access_level_ : Override_params_repository_access_level_.t option;
          [@default None] [@key "override_params[repository_access_level]"]
      override_params_repository_storage_ : string option;
          [@default None] [@key "override_params[repository_storage]"]
      override_params_request_access_enabled_ : bool option;
          [@default None] [@key "override_params[request_access_enabled]"]
      override_params_requirements_access_level_ :
        Override_params_requirements_access_level_.t option;
          [@default None] [@key "override_params[requirements_access_level]"]
      override_params_resolve_outdated_diff_discussions_ : bool option;
          [@default None] [@key "override_params[resolve_outdated_diff_discussions]"]
      override_params_security_and_compliance_access_level_ :
        Override_params_security_and_compliance_access_level_.t option;
          [@default None] [@key "override_params[security_and_compliance_access_level]"]
      override_params_service_desk_enabled_ : bool option;
          [@default None] [@key "override_params[service_desk_enabled]"]
      override_params_shared_runners_enabled_ : bool option;
          [@default None] [@key "override_params[shared_runners_enabled]"]
      override_params_show_default_award_emojis_ : bool option;
          [@default None] [@key "override_params[show_default_award_emojis]"]
      override_params_show_diff_preview_in_email_ : bool option;
          [@default None] [@key "override_params[show_diff_preview_in_email]"]
      override_params_snippets_access_level_ : Override_params_snippets_access_level_.t option;
          [@default None] [@key "override_params[snippets_access_level]"]
      override_params_snippets_enabled_ : bool option;
          [@default None] [@key "override_params[snippets_enabled]"]
      override_params_squash_commit_template_ : string option;
          [@default None] [@key "override_params[squash_commit_template]"]
      override_params_squash_option_ : Override_params_squash_option_.t option;
          [@default None] [@key "override_params[squash_option]"]
      override_params_suggestion_commit_message_ : string option;
          [@default None] [@key "override_params[suggestion_commit_message]"]
      override_params_tag_list_ : Override_params_tag_list_.t option;
          [@default None] [@key "override_params[tag_list]"]
      override_params_topics_ : Override_params_topics_.t option;
          [@default None] [@key "override_params[topics]"]
      override_params_visibility_ : Override_params_visibility_.t option;
          [@default None] [@key "override_params[visibility]"]
      override_params_warn_about_potentially_unwanted_characters_ : bool option;
          [@default None] [@key "override_params[warn_about_potentially_unwanted_characters]"]
      override_params_wiki_access_level_ : Override_params_wiki_access_level_.t option;
          [@default None] [@key "override_params[wiki_access_level]"]
      override_params_wiki_enabled_ : bool option;
          [@default None] [@key "override_params[wiki_enabled]"]
      overwrite : bool; [@default false]
      path : string;
      region : string;
      secret_access_key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Too_many_requests = struct end
    module Service_unavailable = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Too_many_requests
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("429", fun _ -> Ok `Too_many_requests);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/remote-import-s3"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsUserUserId = struct
  module Parameters = struct
    type t = {
      postapiv4projectsuseruserid : Gitlabc_components.PostApiV4ProjectsUserUserId.t;
          [@key "postApiV4ProjectsUserUserId"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/user/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdTerraformStateName = struct
  module Parameters = struct
    type t = {
      id_ : string;
      name : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id_}/terraform/state/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id_", Var (params.id_, String)); ("name", Var (params.name, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdTerraformStateName = struct
  module Parameters = struct
    type t = {
      id_ : string;
      name : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module No_content = struct end
    module Forbidden = struct end
    module Request_entity_too_large = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `No_content
      | `Forbidden
      | `Request_entity_too_large
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("413", fun _ -> Ok `Request_entity_too_large);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id_}/terraform/state/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id_", Var (params.id_, String)); ("name", Var (params.name, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdTerraformStateName = struct
  module Parameters = struct
    type t = {
      id : string option; [@default None] [@key "ID"]
      id_ : string;
      name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `No_content
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id_}/terraform/state/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id_", Var (params.id_, String)); ("name", Var (params.name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("ID", Var (params.id, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdTerraformStateNameLock = struct
  module Parameters = struct
    type t = {
      id : string option; [@default None] [@key "ID"]
      id_ : string;
      name : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id_}/terraform/state/{name}/lock"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id_", Var (params.id_, String)); ("name", Var (params.name, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("ID", Var (params.id, Option String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdTerraformStateNameLock = struct
  module Parameters = struct
    type t = {
      id_ : string;
      name : int;
      postapiv4projectsidterraformstatenamelock :
        Gitlabc_components.PostApiV4ProjectsIdTerraformStateNameLock.t;
          [@key "postApiV4ProjectsIdTerraformStateNameLock"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id_}/terraform/state/{name}/lock"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id_", Var (params.id_, String)); ("name", Var (params.name, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsId = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Accepted
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsId = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsid : Gitlabc_components.PutApiV4ProjectsId.t; [@key "putApiV4ProjectsId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsId = struct
  module Parameters = struct
    type t = {
      id : string;
      license : bool; [@default false]
      statistics : bool; [@default false]
      with_custom_attributes : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("statistics", Var (params.statistics, Bool));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
           ("license", Var (params.license, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdAccessRequests = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/access_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdAccessRequests = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/access_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdAccessRequestsUserId = struct
  module Parameters = struct
    type t = {
      id : string;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/access_requests/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdAccessRequestsUserIdApprove = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidaccessrequestsuseridapprove :
        Gitlabc_components.PutApiV4ProjectsIdAccessRequestsUserIdApprove.t;
          [@key "putApiV4ProjectsIdAccessRequestsUserIdApprove"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/access_requests/{user_id}/approve"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdAccessTokens = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidaccesstokens : Gitlabc_components.PostApiV4ProjectsIdAccessTokens.t;
          [@key "postApiV4ProjectsIdAccessTokens"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/access_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdAccessTokens = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "inactive" -> Ok "inactive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      state : State.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/access_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("state", Var (params.state, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdAccessTokensSelfRotate = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidaccesstokensselfrotate :
        Gitlabc_components.PostApiV4ProjectsIdAccessTokensSelfRotate.t;
          [@key "postApiV4ProjectsIdAccessTokensSelfRotate"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Method_not_allowed = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Method_not_allowed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("405", fun _ -> Ok `Method_not_allowed);
      ]
  end

  let url = "/api/v4/projects/{id}/access_tokens/self/rotate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdAccessTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/access_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdAccessTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/access_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdAccessTokensTokenIdRotate = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidaccesstokenstokenidrotate :
        Gitlabc_components.PostApiV4ProjectsIdAccessTokensTokenIdRotate.t;
          [@key "postApiV4ProjectsIdAccessTokensTokenIdRotate"]
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/access_tokens/{token_id}/rotate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdAlertManagementAlertsAlertIidMetricImages = struct
  module Parameters = struct
    type t = {
      alert_iid : int;
      file : string;
      id : string;
      url : string option; [@default None]
      url_text : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/alert_management_alerts/{alert_iid}/metric_images"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("alert_iid", Var (params.alert_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdAlertManagementAlertsAlertIidMetricImages = struct
  module Parameters = struct
    type t = {
      alert_iid : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/alert_management_alerts/{alert_iid}/metric_images"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("alert_iid", Var (params.alert_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdAlertManagementAlertsAlertIidMetricImagesAuthorize = struct
  module Parameters = struct
    type t = {
      alert_iid : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/alert_management_alerts/{alert_iid}/metric_images/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("alert_iid", Var (params.alert_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdAlertManagementAlertsAlertIidMetricImagesMetricImageId = struct
  module Parameters = struct
    type t = {
      alert_iid : int;
      id : string;
      metric_image_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url =
    "/api/v4/projects/{id}/alert_management_alerts/{alert_iid}/metric_images/{metric_image_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("alert_iid", Var (params.alert_iid, Int));
           ("metric_image_id", Var (params.metric_image_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdAlertManagementAlertsAlertIidMetricImagesMetricImageId = struct
  module Parameters = struct
    type t = {
      alert_iid : int;
      id : string;
      metric_image_id : int;
      url : string option; [@default None]
      url_text : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url =
    "/api/v4/projects/{id}/alert_management_alerts/{alert_iid}/metric_images/{metric_image_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("alert_iid", Var (params.alert_iid, Int));
           ("metric_image_id", Var (params.metric_image_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdArchive = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/archive"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdArtifacts = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Conflict = struct end

    type t =
      [ `Accepted
      | `Unauthorized
      | `Forbidden
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/artifacts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdAuditEvents = struct
  module Parameters = struct
    type t = {
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/audit_events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdAuditEventsAuditEventId = struct
  module Parameters = struct
    type t = {
      audit_event_id : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/audit_events/{audit_event_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("audit_event_id", Var (params.audit_event_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdAvatar = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/avatar"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdBadges = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidbadges : Gitlabc_components.PostApiV4ProjectsIdBadges.t;
          [@key "postApiV4ProjectsIdBadges"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/badges"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdBadges = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("name", Var (params.name, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdBadgesRender = struct
  module Parameters = struct
    type t = {
      id : string;
      image_url : string;
      link_url : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/render"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("link_url", Var (params.link_url, String)); ("image_url", Var (params.image_url, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
      putapiv4projectsidbadgesbadgeid : Gitlabc_components.PutApiV4ProjectsIdBadgesBadgeId.t;
          [@key "putApiV4ProjectsIdBadgesBadgeId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdCatalogPublish = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidcatalogpublish : Gitlabc_components.PostApiV4ProjectsIdCatalogPublish.t;
          [@key "postApiV4ProjectsIdCatalogPublish"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/catalog/publish"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdCiLint = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidcilint : Gitlabc_components.PostApiV4ProjectsIdCiLint.t;
          [@key "postApiV4ProjectsIdCiLint"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/ci/lint"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdCiLint = struct
  module Parameters = struct
    type t = {
      content_ref : string option; [@default None]
      dry_run : bool; [@default false]
      dry_run_ref : string option; [@default None]
      id : int;
      include_jobs : bool option; [@default None]
      ref_ : string option; [@default None] [@key "ref"]
      sha : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/ci/lint"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sha", Var (params.sha, Option String));
           ("content_ref", Var (params.content_ref, Option String));
           ("dry_run", Var (params.dry_run, Bool));
           ("include_jobs", Var (params.include_jobs, Option Bool));
           ("ref", Var (params.ref_, Option String));
           ("dry_run_ref", Var (params.dry_run_ref, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdClusterAgents = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidclusteragents : Gitlabc_components.PostApiV4ProjectsIdClusterAgents.t;
          [@key "postApiV4ProjectsIdClusterAgents"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdClusterAgents = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdClusterAgentsAgentId = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("agent_id", Var (params.agent_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdClusterAgentsAgentId = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("agent_id", Var (params.agent_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdClusterAgentsAgentIdTokens = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
      postapiv4projectsidclusteragentsagentidtokens :
        Gitlabc_components.PostApiV4ProjectsIdClusterAgentsAgentIdTokens.t;
          [@key "postApiV4ProjectsIdClusterAgentsAgentIdTokens"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}/tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("agent_id", Var (params.agent_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdClusterAgentsAgentIdTokens = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}/tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("agent_id", Var (params.agent_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdClusterAgentsAgentIdTokensTokenId = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
      token_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}/tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("agent_id", Var (params.agent_id, Int));
           ("token_id", Var (params.token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdClusterAgentsAgentIdTokensTokenId = struct
  module Parameters = struct
    type t = {
      agent_id : int;
      id : string;
      token_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/cluster_agents/{agent_id}/tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("agent_id", Var (params.agent_id, Int));
           ("token_id", Var (params.token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdClusters = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/clusters"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdClustersUser = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidclustersuser : Gitlabc_components.PostApiV4ProjectsIdClustersUser.t;
          [@key "postApiV4ProjectsIdClustersUser"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/clusters/user"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdClustersClusterId = struct
  module Parameters = struct
    type t = {
      cluster_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/clusters/{cluster_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("cluster_id", Var (params.cluster_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdClustersClusterId = struct
  module Parameters = struct
    type t = {
      cluster_id : int;
      id : string;
      putapiv4projectsidclustersclusterid : Gitlabc_components.PutApiV4ProjectsIdClustersClusterId.t;
          [@key "putApiV4ProjectsIdClustersClusterId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/clusters/{cluster_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("cluster_id", Var (params.cluster_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdClustersClusterId = struct
  module Parameters = struct
    type t = {
      cluster_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/clusters/{cluster_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("cluster_id", Var (params.cluster_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdCreateCiConfig = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/create_ci_config"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdCustomAttributes = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/custom_attributes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
      putapiv4projectsidcustomattributeskey :
        Gitlabc_components.PutApiV4ProjectsIdCustomAttributesKey.t;
          [@key "putApiV4ProjectsIdCustomAttributesKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdDebianDistributions = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsiddebiandistributions :
        Gitlabc_components.PostApiV4ProjectsIdDebianDistributions.t;
          [@key "postApiV4ProjectsIdDebianDistributions"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdDebianDistributions = struct
  module Parameters = struct
    module Architectures = struct
      type t = string list [@@deriving show, eq]
    end

    module Components = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      architectures : Architectures.t option; [@default None]
      codename : string option; [@default None]
      components : Components.t option; [@default None]
      description : string option; [@default None]
      id : string;
      label : string option; [@default None]
      origin : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      suite : string option; [@default None]
      valid_time_duration_seconds : int option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("codename", Var (params.codename, Option String));
           ("suite", Var (params.suite, Option String));
           ("origin", Var (params.origin, Option String));
           ("label", Var (params.label, Option String));
           ("version", Var (params.version, Option String));
           ("description", Var (params.description, Option String));
           ("valid_time_duration_seconds", Var (params.valid_time_duration_seconds, Option Int));
           ("components", Var (params.components, Option (Array String)));
           ("architectures", Var (params.architectures, Option (Array String)));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdDebianDistributionsCodename = struct
  module Parameters = struct
    module Architectures = struct
      type t = string list [@@deriving show, eq]
    end

    module Components = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      architectures : Architectures.t option; [@default None]
      codename : string;
      components : Components.t option; [@default None]
      description : string option; [@default None]
      id : string;
      label : string option; [@default None]
      origin : string option; [@default None]
      suite : string option; [@default None]
      valid_time_duration_seconds : int option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions/{codename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("suite", Var (params.suite, Option String));
           ("origin", Var (params.origin, Option String));
           ("label", Var (params.label, Option String));
           ("version", Var (params.version, Option String));
           ("description", Var (params.description, Option String));
           ("valid_time_duration_seconds", Var (params.valid_time_duration_seconds, Option Int));
           ("components", Var (params.components, Option (Array String)));
           ("architectures", Var (params.architectures, Option (Array String)));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdDebianDistributionsCodename = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
      putapiv4projectsiddebiandistributionscodename :
        Gitlabc_components.PutApiV4ProjectsIdDebianDistributionsCodename.t;
          [@key "putApiV4ProjectsIdDebianDistributionsCodename"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions/{codename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdDebianDistributionsCodename = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions/{codename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdDebianDistributionsCodenameKeyAsc = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/debian_distributions/{codename}/key.asc"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdDeployKeys = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsiddeploykeys : Gitlabc_components.PostApiV4ProjectsIdDeployKeys.t;
          [@key "postApiV4ProjectsIdDeployKeys"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdDeployKeys = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdDeployKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : string;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdDeployKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : string;
      key_id : int;
      putapiv4projectsiddeploykeyskeyid : Gitlabc_components.PutApiV4ProjectsIdDeployKeysKeyId.t;
          [@key "putApiV4ProjectsIdDeployKeysKeyId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdDeployKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : string;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdDeployKeysKeyIdEnable = struct
  module Parameters = struct
    type t = {
      id : string;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_keys/{key_id}/enable"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdDeployTokens = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsiddeploytokens : Gitlabc_components.PostApiV4ProjectsIdDeployTokens.t;
          [@key "postApiV4ProjectsIdDeployTokens"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdDeployTokens = struct
  module Parameters = struct
    type t = {
      active : bool option; [@default None]
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("active", Var (params.active, Option Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdDeployTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdDeployTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deploy_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdDeployments = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsiddeployments : Gitlabc_components.PostApiV4ProjectsIdDeployments.t;
          [@key "postApiV4ProjectsIdDeployments"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdDeployments = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "iid" -> Ok "iid"
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
        | `String "finished_at" -> Ok "finished_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "blocked" -> Ok "blocked"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      environment : string option; [@default None]
      finished_after : string option; [@default None]
      finished_before : string option; [@default None]
      id : string;
      order_by : Order_by.t; [@default "id"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "asc"]
      status : Status.t option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("updated_after", Var (params.updated_after, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("finished_after", Var (params.finished_after, Option String));
           ("finished_before", Var (params.finished_before, Option String));
           ("environment", Var (params.environment, Option String));
           ("status", Var (params.status, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdDeploymentsDeploymentId = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments/{deployment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("deployment_id", Var (params.deployment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdDeploymentsDeploymentId = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      id : string;
      putapiv4projectsiddeploymentsdeploymentid :
        Gitlabc_components.PutApiV4ProjectsIdDeploymentsDeploymentId.t;
          [@key "putApiV4ProjectsIdDeploymentsDeploymentId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments/{deployment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("deployment_id", Var (params.deployment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdDeploymentsDeploymentId = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments/{deployment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("deployment_id", Var (params.deployment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdDeploymentsDeploymentIdApproval = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      id : string;
      postapiv4projectsiddeploymentsdeploymentidapproval :
        Gitlabc_components.PostApiV4ProjectsIdDeploymentsDeploymentIdApproval.t;
          [@key "postApiV4ProjectsIdDeploymentsDeploymentIdApproval"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/deployments/{deployment_id}/approval"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("deployment_id", Var (params.deployment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdDeploymentsDeploymentIdMergeRequests = struct
  module Parameters = struct
    module Approved = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Assignee_username = struct
      type t = string list [@@deriving show, eq]
    end

    module Labels = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_assignee_username_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_labels_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "label_priority" -> Ok "label_priority"
        | `String "milestone_due" -> Ok "milestone_due"
        | `String "popularity" -> Ok "popularity"
        | `String "priority" -> Ok "priority"
        | `String "title" -> Ok "title"
        | `String "updated_at" -> Ok "updated_at"
        | `String "merged_at" -> Ok "merged_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "created-by-me" -> Ok "created-by-me"
        | `String "assigned-to-me" -> Ok "assigned-to-me"
        | `String "created_by_me" -> Ok "created_by_me"
        | `String "assigned_to_me" -> Ok "assigned_to_me"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module State = struct
      let t_of_yojson = function
        | `String "opened" -> Ok "opened"
        | `String "closed" -> Ok "closed"
        | `String "locked" -> Ok "locked"
        | `String "merged" -> Ok "merged"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module View = struct
      let t_of_yojson = function
        | `String "simple" -> Ok "simple"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Wip = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      approved : Approved.t option; [@default None]
      assignee_id : int option; [@default None]
      assignee_username : Assignee_username.t option; [@default None]
      author_id : int option; [@default None]
      author_username : string option; [@default None]
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      deployed_after : string option; [@default None]
      deployed_before : string option; [@default None]
      deployment_id : int;
      environment : string option; [@default None]
      id : string;
      in_ : string option; [@default None] [@key "in"]
      labels : Labels.t option; [@default None]
      merge_user_id : int option; [@default None]
      merge_user_username : string option; [@default None]
      milestone : string option; [@default None]
      my_reaction_emoji : string option; [@default None]
      not_assignee_id_ : int option; [@default None] [@key "not[assignee_id]"]
      not_assignee_username_ : Not_assignee_username_.t option;
          [@default None] [@key "not[assignee_username]"]
      not_author_id_ : int option; [@default None] [@key "not[author_id]"]
      not_author_username_ : string option; [@default None] [@key "not[author_username]"]
      not_labels_ : Not_labels_.t option; [@default None] [@key "not[labels]"]
      not_milestone_ : string option; [@default None] [@key "not[milestone]"]
      not_my_reaction_emoji_ : string option; [@default None] [@key "not[my_reaction_emoji]"]
      not_reviewer_id_ : int option; [@default None] [@key "not[reviewer_id]"]
      not_reviewer_username_ : string option; [@default None] [@key "not[reviewer_username]"]
      order_by : Order_by.t; [@default "created_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      reviewer_id : int option; [@default None]
      reviewer_username : string option; [@default None]
      scope : Scope.t option; [@default None]
      search : string option; [@default None]
      sort : Sort.t; [@default "desc"]
      source_branch : string option; [@default None]
      source_project_id : int option; [@default None]
      state : State.t; [@default "all"]
      target_branch : string option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      view : View.t option; [@default None]
      wip : Wip.t option; [@default None]
      with_labels_details : bool; [@default false]
      with_merge_status_recheck : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/deployments/{deployment_id}/merge_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("deployment_id", Var (params.deployment_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("author_id", Var (params.author_id, Option Int));
           ("author_username", Var (params.author_username, Option String));
           ("assignee_id", Var (params.assignee_id, Option Int));
           ("assignee_username", Var (params.assignee_username, Option (Array String)));
           ("reviewer_username", Var (params.reviewer_username, Option String));
           ("labels", Var (params.labels, Option (Array String)));
           ("milestone", Var (params.milestone, Option String));
           ("my_reaction_emoji", Var (params.my_reaction_emoji, Option String));
           ("reviewer_id", Var (params.reviewer_id, Option Int));
           ("state", Var (params.state, String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("with_labels_details", Var (params.with_labels_details, Bool));
           ("with_merge_status_recheck", Var (params.with_merge_status_recheck, Bool));
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("view", Var (params.view, Option String));
           ("scope", Var (params.scope, Option String));
           ("source_branch", Var (params.source_branch, Option String));
           ("source_project_id", Var (params.source_project_id, Option Int));
           ("target_branch", Var (params.target_branch, Option String));
           ("search", Var (params.search, Option String));
           ("in", Var (params.in_, Option String));
           ("wip", Var (params.wip, Option String));
           ("not[author_id]", Var (params.not_author_id_, Option Int));
           ("not[author_username]", Var (params.not_author_username_, Option String));
           ("not[assignee_id]", Var (params.not_assignee_id_, Option Int));
           ("not[assignee_username]", Var (params.not_assignee_username_, Option (Array String)));
           ("not[reviewer_username]", Var (params.not_reviewer_username_, Option String));
           ("not[labels]", Var (params.not_labels_, Option (Array String)));
           ("not[milestone]", Var (params.not_milestone_, Option String));
           ("not[my_reaction_emoji]", Var (params.not_my_reaction_emoji_, Option String));
           ("not[reviewer_id]", Var (params.not_reviewer_id_, Option Int));
           ("deployed_before", Var (params.deployed_before, Option String));
           ("deployed_after", Var (params.deployed_after, Option String));
           ("environment", Var (params.environment, Option String));
           ("approved", Var (params.approved, Option String));
           ("merge_user_id", Var (params.merge_user_id, Option Int));
           ("merge_user_username", Var (params.merge_user_username, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdEnvironments = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidenvironments : Gitlabc_components.PostApiV4ProjectsIdEnvironments.t;
          [@key "postApiV4ProjectsIdEnvironments"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdEnvironments = struct
  module Parameters = struct
    module States = struct
      let t_of_yojson = function
        | `String "stopped" -> Ok "stopped"
        | `String "stopping" -> Ok "stopping"
        | `String "available" -> Ok "available"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      name : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      states : States.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("name", Var (params.name, Option String));
           ("search", Var (params.search, Option String));
           ("states", Var (params.states, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdEnvironmentsReviewApps = struct
  module Parameters = struct
    type t = {
      before : string option; [@default None]
      dry_run : bool; [@default true]
      id : string;
      limit : int; [@default 100]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/review_apps"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("before", Var (params.before, Option String));
           ("limit", Var (params.limit, Int));
           ("dry_run", Var (params.dry_run, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdEnvironmentsStopStale = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidenvironmentsstopstale :
        Gitlabc_components.PostApiV4ProjectsIdEnvironmentsStopStale.t;
          [@key "postApiV4ProjectsIdEnvironmentsStopStale"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/stop_stale"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdEnvironmentsEnvironmentId = struct
  module Parameters = struct
    type t = {
      environment_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/{environment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("environment_id", Var (params.environment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdEnvironmentsEnvironmentId = struct
  module Parameters = struct
    type t = {
      environment_id : int;
      id : string;
      putapiv4projectsidenvironmentsenvironmentid :
        Gitlabc_components.PutApiV4ProjectsIdEnvironmentsEnvironmentId.t;
          [@key "putApiV4ProjectsIdEnvironmentsEnvironmentId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/{environment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("environment_id", Var (params.environment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdEnvironmentsEnvironmentId = struct
  module Parameters = struct
    type t = {
      environment_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/{environment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("environment_id", Var (params.environment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdEnvironmentsEnvironmentIdStop = struct
  module Parameters = struct
    type t = {
      environment_id : int;
      id : string;
      postapiv4projectsidenvironmentsenvironmentidstop :
        Gitlabc_components.PostApiV4ProjectsIdEnvironmentsEnvironmentIdStop.t;
          [@key "postApiV4ProjectsIdEnvironmentsEnvironmentIdStop"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/environments/{environment_id}/stop"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("environment_id", Var (params.environment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdErrorTrackingClientKeys = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/client_keys"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdErrorTrackingClientKeys = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/client_keys"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdErrorTrackingClientKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : string;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/client_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PatchApiV4ProjectsIdErrorTrackingSettings = struct
  module Parameters = struct
    type t = {
      id : string;
      patchapiv4projectsiderrortrackingsettings :
        Gitlabc_components.PatchApiV4ProjectsIdErrorTrackingSettings.t;
          [@key "patchApiV4ProjectsIdErrorTrackingSettings"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/settings"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module PutApiV4ProjectsIdErrorTrackingSettings = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsiderrortrackingsettings :
        Gitlabc_components.PutApiV4ProjectsIdErrorTrackingSettings.t;
          [@key "putApiV4ProjectsIdErrorTrackingSettings"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/settings"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdErrorTrackingSettings = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/error_tracking/settings"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdEvents = struct
  module Parameters = struct
    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Target_type = struct
      let t_of_yojson = function
        | `String "issue" -> Ok "issue"
        | `String "milestone" -> Ok "milestone"
        | `String "merge_request" -> Ok "merge_request"
        | `String "note" -> Ok "note"
        | `String "project" -> Ok "project"
        | `String "snippet" -> Ok "snippet"
        | `String "user" -> Ok "user"
        | `String "wiki" -> Ok "wiki"
        | `String "design" -> Ok "design"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      action : string option; [@default None]
      after : string option; [@default None]
      before : string option; [@default None]
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "desc"]
      target_type : Target_type.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("action", Var (params.action, Option String));
           ("target_type", Var (params.target_type, Option String));
           ("before", Var (params.before, Option String));
           ("after", Var (params.after, Option String));
           ("sort", Var (params.sort, String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdExport = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidexport : Gitlabc_components.PostApiV4ProjectsIdExport.t;
          [@key "postApiV4ProjectsIdExport"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Too_many_requests = struct end
    module Service_unavailable = struct end

    type t =
      [ `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Too_many_requests
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("429", fun _ -> Ok `Too_many_requests);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdExport = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdExportDownload = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export/download"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdExportRelations = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidexportrelations : Gitlabc_components.PostApiV4ProjectsIdExportRelations.t;
          [@key "postApiV4ProjectsIdExportRelations"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export_relations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdExportRelationsDownload = struct
  module Parameters = struct
    type t = {
      batch_number : int option; [@default None]
      batched : bool option; [@default None]
      id : string;
      relation : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Internal_server_error = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Internal_server_error
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("500", fun _ -> Ok `Internal_server_error);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export_relations/download"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("relation", Var (params.relation, String));
           ("batched", Var (params.batched, Option Bool));
           ("batch_number", Var (params.batch_number, Option Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdExportRelationsStatus = struct
  module Parameters = struct
    type t = {
      id : string;
      relation : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/export_relations/status"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("relation", Var (params.relation, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdFeatureFlags = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidfeatureflags : Gitlabc_components.PostApiV4ProjectsIdFeatureFlags.t;
          [@key "postApiV4ProjectsIdFeatureFlags"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdFeatureFlags = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "enabled" -> Ok "enabled"
        | `String "disabled" -> Ok "disabled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdFeatureFlagsFeatureFlagName = struct
  module Parameters = struct
    type t = {
      feature_flag_name : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags/{feature_flag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("feature_flag_name", Var (params.feature_flag_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdFeatureFlagsFeatureFlagName = struct
  module Parameters = struct
    type t = {
      feature_flag_name : string;
      id : string;
      putapiv4projectsidfeatureflagsfeatureflagname :
        Gitlabc_components.PutApiV4ProjectsIdFeatureFlagsFeatureFlagName.t;
          [@key "putApiV4ProjectsIdFeatureFlagsFeatureFlagName"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags/{feature_flag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("feature_flag_name", Var (params.feature_flag_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdFeatureFlagsFeatureFlagName = struct
  module Parameters = struct
    type t = {
      feature_flag_name : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags/{feature_flag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("feature_flag_name", Var (params.feature_flag_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdFeatureFlagsUserLists = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidfeatureflagsuserlists :
        Gitlabc_components.PostApiV4ProjectsIdFeatureFlagsUserLists.t;
          [@key "postApiV4ProjectsIdFeatureFlagsUserLists"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags_user_lists"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdFeatureFlagsUserLists = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags_user_lists"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("search", Var (params.search, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdFeatureFlagsUserListsIid = struct
  module Parameters = struct
    type t = {
      id : string;
      iid : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags_user_lists/{iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("iid", Var (params.iid, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdFeatureFlagsUserListsIid = struct
  module Parameters = struct
    type t = {
      id : string;
      iid : string;
      putapiv4projectsidfeatureflagsuserlistsiid :
        Gitlabc_components.PutApiV4ProjectsIdFeatureFlagsUserListsIid.t;
          [@key "putApiV4ProjectsIdFeatureFlagsUserListsIid"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags_user_lists/{iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("iid", Var (params.iid, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdFeatureFlagsUserListsIid = struct
  module Parameters = struct
    type t = {
      id : string;
      iid : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/feature_flags_user_lists/{iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("iid", Var (params.iid, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdFork = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/fork"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdFork = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidfork : Gitlabc_components.PostApiV4ProjectsIdFork.t;
          [@key "postApiV4ProjectsIdFork"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `Created
      | `Forbidden
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/fork"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdForkForkedFromId = struct
  module Parameters = struct
    type t = {
      forked_from_id : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/fork/{forked_from_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("forked_from_id", Var (params.forked_from_id, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdForks = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "name" -> Ok "name"
        | `String "path" -> Ok "path"
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
        | `String "last_activity_at" -> Ok "last_activity_at"
        | `String "similarity" -> Ok "similarity"
        | `String "star_count" -> Ok "star_count"
        | `String "storage_size" -> Ok "storage_size"
        | `String "repository_size" -> Ok "repository_size"
        | `String "wiki_size" -> Ok "wiki_size"
        | `String "packages_size" -> Ok "packages_size"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Topic = struct
      type t = string list [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      archived : bool option; [@default None]
      id : string;
      id_after : int option; [@default None]
      id_before : int option; [@default None]
      imported : bool; [@default false]
      include_hidden : bool; [@default false]
      include_pending_delete : bool option; [@default None]
      last_activity_after : string option; [@default None]
      last_activity_before : string option; [@default None]
      marked_for_deletion_on : string option; [@default None]
      membership : bool; [@default false]
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default "created_at"]
      owned : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      repository_checksum_failed : bool; [@default false]
      repository_storage : string option; [@default None]
      search : string option; [@default None]
      search_namespaces : bool option; [@default None]
      simple : bool; [@default false]
      sort : Sort.t; [@default "desc"]
      starred : bool; [@default false]
      topic : Topic.t option; [@default None]
      topic_id : int option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      visibility : Visibility.t option; [@default None]
      wiki_checksum_failed : bool; [@default false]
      with_custom_attributes : bool; [@default false]
      with_issues_enabled : bool; [@default false]
      with_merge_requests_enabled : bool; [@default false]
      with_programming_language : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/forks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("archived", Var (params.archived, Option Bool));
           ("visibility", Var (params.visibility, Option String));
           ("search", Var (params.search, Option String));
           ("search_namespaces", Var (params.search_namespaces, Option Bool));
           ("owned", Var (params.owned, Bool));
           ("starred", Var (params.starred, Bool));
           ("imported", Var (params.imported, Bool));
           ("membership", Var (params.membership, Bool));
           ("with_issues_enabled", Var (params.with_issues_enabled, Bool));
           ("with_merge_requests_enabled", Var (params.with_merge_requests_enabled, Bool));
           ("with_programming_language", Var (params.with_programming_language, Option String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("id_after", Var (params.id_after, Option Int));
           ("id_before", Var (params.id_before, Option Int));
           ("last_activity_after", Var (params.last_activity_after, Option String));
           ("last_activity_before", Var (params.last_activity_before, Option String));
           ("repository_storage", Var (params.repository_storage, Option String));
           ("topic", Var (params.topic, Option (Array String)));
           ("topic_id", Var (params.topic_id, Option Int));
           ("updated_before", Var (params.updated_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("include_pending_delete", Var (params.include_pending_delete, Option Bool));
           ("wiki_checksum_failed", Var (params.wiki_checksum_failed, Bool));
           ("repository_checksum_failed", Var (params.repository_checksum_failed, Bool));
           ("include_hidden", Var (params.include_hidden, Bool));
           ("marked_for_deletion_on", Var (params.marked_for_deletion_on, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("simple", Var (params.simple, Bool));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdFreezePeriods = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidfreezeperiods : Gitlabc_components.PostApiV4ProjectsIdFreezePeriods.t;
          [@key "postApiV4ProjectsIdFreezePeriods"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/freeze_periods"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdFreezePeriods = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/freeze_periods"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdFreezePeriodsFreezePeriodId = struct
  module Parameters = struct
    type t = {
      freeze_period_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end

    type t =
      [ `No_content
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("401", fun _ -> Ok `Unauthorized) ]
  end

  let url = "/api/v4/projects/{id}/freeze_periods/{freeze_period_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("freeze_period_id", Var (params.freeze_period_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdFreezePeriodsFreezePeriodId = struct
  module Parameters = struct
    type t = {
      freeze_period_id : int;
      id : string;
      putapiv4projectsidfreezeperiodsfreezeperiodid :
        Gitlabc_components.PutApiV4ProjectsIdFreezePeriodsFreezePeriodId.t;
          [@key "putApiV4ProjectsIdFreezePeriodsFreezePeriodId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/freeze_periods/{freeze_period_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("freeze_period_id", Var (params.freeze_period_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdFreezePeriodsFreezePeriodId = struct
  module Parameters = struct
    type t = {
      freeze_period_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/freeze_periods/{freeze_period_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("freeze_period_id", Var (params.freeze_period_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdGroups = struct
  module Parameters = struct
    module Skip_groups = struct
      type t = int list [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      shared_min_access_level : int option; [@default None]
      shared_visible_only : bool; [@default false]
      skip_groups : Skip_groups.t option; [@default None]
      with_shared : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("search", Var (params.search, Option String));
           ("skip_groups", Var (params.skip_groups, Option (Array Int)));
           ("with_shared", Var (params.with_shared, Bool));
           ("shared_visible_only", Var (params.shared_visible_only, Bool));
           ("shared_min_access_level", Var (params.shared_min_access_level, Option Int));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdHooks = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidhooks : Gitlabc_components.PostApiV4ProjectsIdHooks.t;
          [@key "postApiV4ProjectsIdHooks"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdHooks = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
      putapiv4projectsidhookshookid : Gitlabc_components.PutApiV4ProjectsIdHooksHookId.t;
          [@key "putApiV4ProjectsIdHooksHookId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdHooksHookIdCustomHeadersKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/custom_headers/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookIdCustomHeadersKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
      putapiv4projectsidhookshookidcustomheaderskey :
        Gitlabc_components.PutApiV4ProjectsIdHooksHookIdCustomHeadersKey.t;
          [@key "putApiV4ProjectsIdHooksHookIdCustomHeadersKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/custom_headers/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdHooksHookIdEvents = struct
  module Parameters = struct
    module Status = struct
      module Items = struct
        let t_of_yojson = function
          | `String "100" -> Ok "100"
          | `String "101" -> Ok "101"
          | `String "102" -> Ok "102"
          | `String "103" -> Ok "103"
          | `String "200" -> Ok "200"
          | `String "201" -> Ok "201"
          | `String "202" -> Ok "202"
          | `String "203" -> Ok "203"
          | `String "204" -> Ok "204"
          | `String "205" -> Ok "205"
          | `String "206" -> Ok "206"
          | `String "207" -> Ok "207"
          | `String "208" -> Ok "208"
          | `String "226" -> Ok "226"
          | `String "300" -> Ok "300"
          | `String "301" -> Ok "301"
          | `String "302" -> Ok "302"
          | `String "303" -> Ok "303"
          | `String "304" -> Ok "304"
          | `String "305" -> Ok "305"
          | `String "306" -> Ok "306"
          | `String "307" -> Ok "307"
          | `String "308" -> Ok "308"
          | `String "400" -> Ok "400"
          | `String "401" -> Ok "401"
          | `String "402" -> Ok "402"
          | `String "403" -> Ok "403"
          | `String "404" -> Ok "404"
          | `String "405" -> Ok "405"
          | `String "406" -> Ok "406"
          | `String "407" -> Ok "407"
          | `String "408" -> Ok "408"
          | `String "409" -> Ok "409"
          | `String "410" -> Ok "410"
          | `String "411" -> Ok "411"
          | `String "412" -> Ok "412"
          | `String "413" -> Ok "413"
          | `String "414" -> Ok "414"
          | `String "415" -> Ok "415"
          | `String "416" -> Ok "416"
          | `String "417" -> Ok "417"
          | `String "421" -> Ok "421"
          | `String "422" -> Ok "422"
          | `String "423" -> Ok "423"
          | `String "424" -> Ok "424"
          | `String "425" -> Ok "425"
          | `String "426" -> Ok "426"
          | `String "428" -> Ok "428"
          | `String "429" -> Ok "429"
          | `String "431" -> Ok "431"
          | `String "451" -> Ok "451"
          | `String "500" -> Ok "500"
          | `String "501" -> Ok "501"
          | `String "502" -> Ok "502"
          | `String "503" -> Ok "503"
          | `String "504" -> Ok "504"
          | `String "505" -> Ok "505"
          | `String "506" -> Ok "506"
          | `String "507" -> Ok "507"
          | `String "508" -> Ok "508"
          | `String "509" -> Ok "509"
          | `String "510" -> Ok "510"
          | `String "511" -> Ok "511"
          | `String "successful" -> Ok "successful"
          | `String "client_failure" -> Ok "client_failure"
          | `String "server_failure" -> Ok "server_failure"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      hook_id : int;
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
      status : Status.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("status", Var (params.status, Option (Array String)));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdHooksHookIdEventsHookLogIdResend = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      hook_log_id : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end
    module Too_many_requests = struct end

    type t =
      [ `Created
      | `Not_found
      | `Unprocessable_entity
      | `Too_many_requests
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("429", fun _ -> Ok `Too_many_requests);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/events/{hook_log_id}/resend"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("hook_id", Var (params.hook_id, Int));
           ("hook_log_id", Var (params.hook_log_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdHooksHookIdTestTrigger = struct
  module Parameters = struct
    module Trigger = struct
      let t_of_yojson = function
        | `String "confidential_issues_events" -> Ok "confidential_issues_events"
        | `String "confidential_note_events" -> Ok "confidential_note_events"
        | `String "deployment_events" -> Ok "deployment_events"
        | `String "emoji_events" -> Ok "emoji_events"
        | `String "feature_flag_events" -> Ok "feature_flag_events"
        | `String "issues_events" -> Ok "issues_events"
        | `String "job_events" -> Ok "job_events"
        | `String "merge_requests_events" -> Ok "merge_requests_events"
        | `String "note_events" -> Ok "note_events"
        | `String "pipeline_events" -> Ok "pipeline_events"
        | `String "push_events" -> Ok "push_events"
        | `String "releases_events" -> Ok "releases_events"
        | `String "resource_access_token_events" -> Ok "resource_access_token_events"
        | `String "tag_push_events" -> Ok "tag_push_events"
        | `String "wiki_page_events" -> Ok "wiki_page_events"
        | `String "vulnerability_events" -> Ok "vulnerability_events"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      hook_id : int;
      id : int;
      trigger : Trigger.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end
    module Too_many_requests = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      | `Too_many_requests
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("429", fun _ -> Ok `Too_many_requests);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/test/{trigger}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("trigger", Var (params.trigger, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdHooksHookIdUrlVariablesKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/url_variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookIdUrlVariablesKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
      putapiv4projectsidhookshookidurlvariableskey :
        Gitlabc_components.PutApiV4ProjectsIdHooksHookIdUrlVariablesKey.t;
          [@key "putApiV4ProjectsIdHooksHookIdUrlVariablesKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/url_variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdHousekeeping = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidhousekeeping : Gitlabc_components.PostApiV4ProjectsIdHousekeeping.t;
          [@key "postApiV4ProjectsIdHousekeeping"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Conflict = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/housekeeping"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdImport = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/import"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdImportProjectMembersProjectId = struct
  module Parameters = struct
    type t = {
      id : string;
      project_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/import_project_members/{project_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("project_id", Var (params.project_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdIntegrations = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdIntegrationsAppleAppStore = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsappleappstore :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsAppleAppStore.t;
          [@key "putApiV4ProjectsIdIntegrationsAppleAppStore"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/apple-app-store"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsAsana = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsasana : Gitlabc_components.PutApiV4ProjectsIdIntegrationsAsana.t;
          [@key "putApiV4ProjectsIdIntegrationsAsana"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/asana"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsAssembla = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsassembla :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsAssembla.t;
          [@key "putApiV4ProjectsIdIntegrationsAssembla"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/assembla"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsBamboo = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsbamboo :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsBamboo.t;
          [@key "putApiV4ProjectsIdIntegrationsBamboo"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/bamboo"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsBugzilla = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsbugzilla :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsBugzilla.t;
          [@key "putApiV4ProjectsIdIntegrationsBugzilla"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/bugzilla"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsBuildkite = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsbuildkite :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsBuildkite.t;
          [@key "putApiV4ProjectsIdIntegrationsBuildkite"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/buildkite"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsCampfire = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationscampfire :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsCampfire.t;
          [@key "putApiV4ProjectsIdIntegrationsCampfire"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/campfire"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsClickup = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsclickup :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsClickup.t;
          [@key "putApiV4ProjectsIdIntegrationsClickup"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/clickup"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsConfluence = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsconfluence :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsConfluence.t;
          [@key "putApiV4ProjectsIdIntegrationsConfluence"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/confluence"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsCustomIssueTracker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationscustomissuetracker :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsCustomIssueTracker.t;
          [@key "putApiV4ProjectsIdIntegrationsCustomIssueTracker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/custom-issue-tracker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsDatadog = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsdatadog :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsDatadog.t;
          [@key "putApiV4ProjectsIdIntegrationsDatadog"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/datadog"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsDiffblueCover = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsdiffbluecover :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsDiffblueCover.t;
          [@key "putApiV4ProjectsIdIntegrationsDiffblueCover"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/diffblue-cover"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsDiscord = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsdiscord :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsDiscord.t;
          [@key "putApiV4ProjectsIdIntegrationsDiscord"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/discord"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsDroneCi = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsdroneci :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsDroneCi.t;
          [@key "putApiV4ProjectsIdIntegrationsDroneCi"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/drone-ci"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsEmailsOnPush = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsemailsonpush :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsEmailsOnPush.t;
          [@key "putApiV4ProjectsIdIntegrationsEmailsOnPush"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/emails-on-push"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsEwm = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsewm : Gitlabc_components.PutApiV4ProjectsIdIntegrationsEwm.t;
          [@key "putApiV4ProjectsIdIntegrationsEwm"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/ewm"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsExternalWiki = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsexternalwiki :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsExternalWiki.t;
          [@key "putApiV4ProjectsIdIntegrationsExternalWiki"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/external-wiki"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGitGuardian = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgitguardian :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsGitGuardian.t;
          [@key "putApiV4ProjectsIdIntegrationsGitGuardian"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/git-guardian"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGithub = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgithub :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsGithub.t;
          [@key "putApiV4ProjectsIdIntegrationsGithub"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/github"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGitlabSlackApplication = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgitlabslackapplication :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsGitlabSlackApplication.t;
          [@key "putApiV4ProjectsIdIntegrationsGitlabSlackApplication"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/gitlab-slack-application"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGoogleCloudPlatformArtifactRegistry = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgooglecloudplatformartifactregistry :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsGoogleCloudPlatformArtifactRegistry.t;
          [@key "putApiV4ProjectsIdIntegrationsGoogleCloudPlatformArtifactRegistry"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/google-cloud-platform-artifact-registry"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGoogleCloudPlatformWorkloadIdentityFederation = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgooglecloudplatformworkloadidentityfederation :
        Gitlabc_components
        .PutApiV4ProjectsIdIntegrationsGoogleCloudPlatformWorkloadIdentityFederation
        .t;
          [@key "putApiV4ProjectsIdIntegrationsGoogleCloudPlatformWorkloadIdentityFederation"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/google-cloud-platform-workload-identity-federation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsGooglePlay = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsgoogleplay :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsGooglePlay.t;
          [@key "putApiV4ProjectsIdIntegrationsGooglePlay"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/google-play"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsHangoutsChat = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationshangoutschat :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsHangoutsChat.t;
          [@key "putApiV4ProjectsIdIntegrationsHangoutsChat"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/hangouts-chat"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsHarbor = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsharbor :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsHarbor.t;
          [@key "putApiV4ProjectsIdIntegrationsHarbor"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/harbor"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsIrker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsirker : Gitlabc_components.PutApiV4ProjectsIdIntegrationsIrker.t;
          [@key "putApiV4ProjectsIdIntegrationsIrker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/irker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsJenkins = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsjenkins :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsJenkins.t;
          [@key "putApiV4ProjectsIdIntegrationsJenkins"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/jenkins"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsJira = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsjira : Gitlabc_components.PutApiV4ProjectsIdIntegrationsJira.t;
          [@key "putApiV4ProjectsIdIntegrationsJira"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/jira"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsJiraCloudApp = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsjiracloudapp :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsJiraCloudApp.t;
          [@key "putApiV4ProjectsIdIntegrationsJiraCloudApp"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/jira-cloud-app"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsMatrix = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmatrix :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMatrix.t;
          [@key "putApiV4ProjectsIdIntegrationsMatrix"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/matrix"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsMattermost = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmattermost :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMattermost.t;
          [@key "putApiV4ProjectsIdIntegrationsMattermost"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/mattermost"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsMattermostSlashCommands = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmattermostslashcommands :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMattermostSlashCommands.t;
          [@key "putApiV4ProjectsIdIntegrationsMattermostSlashCommands"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/mattermost-slash-commands"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdIntegrationsMattermostSlashCommandsTrigger = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidintegrationsmattermostslashcommandstrigger :
        Gitlabc_components.PostApiV4ProjectsIdIntegrationsMattermostSlashCommandsTrigger.t;
          [@key "postApiV4ProjectsIdIntegrationsMattermostSlashCommandsTrigger"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/mattermost_slash_commands/trigger"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PutApiV4ProjectsIdIntegrationsMicrosoftTeams = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmicrosoftteams :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMicrosoftTeams.t;
          [@key "putApiV4ProjectsIdIntegrationsMicrosoftTeams"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/microsoft-teams"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsMockCi = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmockci :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMockCi.t;
          [@key "putApiV4ProjectsIdIntegrationsMockCi"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/mock-ci"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsMockMonitoring = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsmockmonitoring :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsMockMonitoring.t;
          [@key "putApiV4ProjectsIdIntegrationsMockMonitoring"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/mock-monitoring"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPackagist = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationspackagist :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPackagist.t;
          [@key "putApiV4ProjectsIdIntegrationsPackagist"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/packagist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPhorge = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsphorge :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPhorge.t;
          [@key "putApiV4ProjectsIdIntegrationsPhorge"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/phorge"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPipelinesEmail = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationspipelinesemail :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPipelinesEmail.t;
          [@key "putApiV4ProjectsIdIntegrationsPipelinesEmail"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/pipelines-email"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPivotaltracker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationspivotaltracker :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPivotaltracker.t;
          [@key "putApiV4ProjectsIdIntegrationsPivotaltracker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/pivotaltracker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPumble = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationspumble :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPumble.t;
          [@key "putApiV4ProjectsIdIntegrationsPumble"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/pumble"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsPushover = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationspushover :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsPushover.t;
          [@key "putApiV4ProjectsIdIntegrationsPushover"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/pushover"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsRedmine = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsredmine :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsRedmine.t;
          [@key "putApiV4ProjectsIdIntegrationsRedmine"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/redmine"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsSlack = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsslack : Gitlabc_components.PutApiV4ProjectsIdIntegrationsSlack.t;
          [@key "putApiV4ProjectsIdIntegrationsSlack"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/slack"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsSlackSlashCommands = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsslackslashcommands :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsSlackSlashCommands.t;
          [@key "putApiV4ProjectsIdIntegrationsSlackSlashCommands"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/slack-slash-commands"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdIntegrationsSlackSlashCommandsTrigger = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidintegrationsslackslashcommandstrigger :
        Gitlabc_components.PostApiV4ProjectsIdIntegrationsSlackSlashCommandsTrigger.t;
          [@key "postApiV4ProjectsIdIntegrationsSlackSlashCommandsTrigger"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/slack_slash_commands/trigger"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PutApiV4ProjectsIdIntegrationsSquashTm = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationssquashtm :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsSquashTm.t;
          [@key "putApiV4ProjectsIdIntegrationsSquashTm"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/squash-tm"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsTeamcity = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsteamcity :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsTeamcity.t;
          [@key "putApiV4ProjectsIdIntegrationsTeamcity"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/teamcity"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsTelegram = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationstelegram :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsTelegram.t;
          [@key "putApiV4ProjectsIdIntegrationsTelegram"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/telegram"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsUnifyCircuit = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsunifycircuit :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsUnifyCircuit.t;
          [@key "putApiV4ProjectsIdIntegrationsUnifyCircuit"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/unify-circuit"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsWebexTeams = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationswebexteams :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsWebexTeams.t;
          [@key "putApiV4ProjectsIdIntegrationsWebexTeams"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/webex-teams"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsYoutrack = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationsyoutrack :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsYoutrack.t;
          [@key "putApiV4ProjectsIdIntegrationsYoutrack"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/youtrack"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdIntegrationsZentao = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidintegrationszentao :
        Gitlabc_components.PutApiV4ProjectsIdIntegrationsZentao.t;
          [@key "putApiV4ProjectsIdIntegrationsZentao"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/zentao"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module DeleteApiV4ProjectsIdIntegrationsSlug = struct
  module Parameters = struct
    module Slug = struct
      let t_of_yojson = function
        | `String "apple-app-store" -> Ok "apple-app-store"
        | `String "asana" -> Ok "asana"
        | `String "assembla" -> Ok "assembla"
        | `String "bamboo" -> Ok "bamboo"
        | `String "bugzilla" -> Ok "bugzilla"
        | `String "buildkite" -> Ok "buildkite"
        | `String "campfire" -> Ok "campfire"
        | `String "confluence" -> Ok "confluence"
        | `String "custom-issue-tracker" -> Ok "custom-issue-tracker"
        | `String "datadog" -> Ok "datadog"
        | `String "diffblue-cover" -> Ok "diffblue-cover"
        | `String "discord" -> Ok "discord"
        | `String "drone-ci" -> Ok "drone-ci"
        | `String "emails-on-push" -> Ok "emails-on-push"
        | `String "external-wiki" -> Ok "external-wiki"
        | `String "gitlab-slack-application" -> Ok "gitlab-slack-application"
        | `String "google-play" -> Ok "google-play"
        | `String "hangouts-chat" -> Ok "hangouts-chat"
        | `String "harbor" -> Ok "harbor"
        | `String "irker" -> Ok "irker"
        | `String "jenkins" -> Ok "jenkins"
        | `String "jira" -> Ok "jira"
        | `String "jira-cloud-app" -> Ok "jira-cloud-app"
        | `String "matrix" -> Ok "matrix"
        | `String "mattermost-slash-commands" -> Ok "mattermost-slash-commands"
        | `String "slack-slash-commands" -> Ok "slack-slash-commands"
        | `String "packagist" -> Ok "packagist"
        | `String "phorge" -> Ok "phorge"
        | `String "pipelines-email" -> Ok "pipelines-email"
        | `String "pivotaltracker" -> Ok "pivotaltracker"
        | `String "pumble" -> Ok "pumble"
        | `String "pushover" -> Ok "pushover"
        | `String "redmine" -> Ok "redmine"
        | `String "ewm" -> Ok "ewm"
        | `String "youtrack" -> Ok "youtrack"
        | `String "clickup" -> Ok "clickup"
        | `String "slack" -> Ok "slack"
        | `String "microsoft-teams" -> Ok "microsoft-teams"
        | `String "mattermost" -> Ok "mattermost"
        | `String "teamcity" -> Ok "teamcity"
        | `String "telegram" -> Ok "telegram"
        | `String "unify-circuit" -> Ok "unify-circuit"
        | `String "webex-teams" -> Ok "webex-teams"
        | `String "zentao" -> Ok "zentao"
        | `String "squash-tm" -> Ok "squash-tm"
        | `String "github" -> Ok "github"
        | `String "git-guardian" -> Ok "git-guardian"
        | `String "google-cloud-platform-artifact-registry" ->
            Ok "google-cloud-platform-artifact-registry"
        | `String "google-cloud-platform-workload-identity-federation" ->
            Ok "google-cloud-platform-workload-identity-federation"
        | `String "mock-ci" -> Ok "mock-ci"
        | `String "mock-monitoring" -> Ok "mock-monitoring"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : int;
      slug : Slug.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdIntegrationsSlug = struct
  module Parameters = struct
    module Slug = struct
      let t_of_yojson = function
        | `String "apple-app-store" -> Ok "apple-app-store"
        | `String "asana" -> Ok "asana"
        | `String "assembla" -> Ok "assembla"
        | `String "bamboo" -> Ok "bamboo"
        | `String "bugzilla" -> Ok "bugzilla"
        | `String "buildkite" -> Ok "buildkite"
        | `String "campfire" -> Ok "campfire"
        | `String "confluence" -> Ok "confluence"
        | `String "custom-issue-tracker" -> Ok "custom-issue-tracker"
        | `String "datadog" -> Ok "datadog"
        | `String "diffblue-cover" -> Ok "diffblue-cover"
        | `String "discord" -> Ok "discord"
        | `String "drone-ci" -> Ok "drone-ci"
        | `String "emails-on-push" -> Ok "emails-on-push"
        | `String "external-wiki" -> Ok "external-wiki"
        | `String "gitlab-slack-application" -> Ok "gitlab-slack-application"
        | `String "google-play" -> Ok "google-play"
        | `String "hangouts-chat" -> Ok "hangouts-chat"
        | `String "harbor" -> Ok "harbor"
        | `String "irker" -> Ok "irker"
        | `String "jenkins" -> Ok "jenkins"
        | `String "jira" -> Ok "jira"
        | `String "jira-cloud-app" -> Ok "jira-cloud-app"
        | `String "matrix" -> Ok "matrix"
        | `String "mattermost-slash-commands" -> Ok "mattermost-slash-commands"
        | `String "slack-slash-commands" -> Ok "slack-slash-commands"
        | `String "packagist" -> Ok "packagist"
        | `String "phorge" -> Ok "phorge"
        | `String "pipelines-email" -> Ok "pipelines-email"
        | `String "pivotaltracker" -> Ok "pivotaltracker"
        | `String "pumble" -> Ok "pumble"
        | `String "pushover" -> Ok "pushover"
        | `String "redmine" -> Ok "redmine"
        | `String "ewm" -> Ok "ewm"
        | `String "youtrack" -> Ok "youtrack"
        | `String "clickup" -> Ok "clickup"
        | `String "slack" -> Ok "slack"
        | `String "microsoft-teams" -> Ok "microsoft-teams"
        | `String "mattermost" -> Ok "mattermost"
        | `String "teamcity" -> Ok "teamcity"
        | `String "telegram" -> Ok "telegram"
        | `String "unify-circuit" -> Ok "unify-circuit"
        | `String "webex-teams" -> Ok "webex-teams"
        | `String "zentao" -> Ok "zentao"
        | `String "squash-tm" -> Ok "squash-tm"
        | `String "github" -> Ok "github"
        | `String "git-guardian" -> Ok "git-guardian"
        | `String "google-cloud-platform-artifact-registry" ->
            Ok "google-cloud-platform-artifact-registry"
        | `String "google-cloud-platform-workload-identity-federation" ->
            Ok "google-cloud-platform-workload-identity-federation"
        | `String "mock-ci" -> Ok "mock-ci"
        | `String "mock-monitoring" -> Ok "mock-monitoring"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : int;
      slug : Slug.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/integrations/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdInvitations = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidinvitations : Gitlabc_components.PostApiV4ProjectsIdInvitations.t;
          [@key "postApiV4ProjectsIdInvitations"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/invitations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdInvitations = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      query : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/invitations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("query", Var (params.query, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdInvitationsEmail = struct
  module Parameters = struct
    type t = {
      email : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/invitations/{email}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("email", Var (params.email, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdInvitationsEmail = struct
  module Parameters = struct
    type t = {
      email : string;
      id : string;
      putapiv4projectsidinvitationsemail : Gitlabc_components.PutApiV4ProjectsIdInvitationsEmail.t;
          [@key "putApiV4ProjectsIdInvitationsEmail"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/invitations/{email}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("email", Var (params.email, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdInvitedGroups = struct
  module Parameters = struct
    module Relation = struct
      module Items = struct
        let t_of_yojson = function
          | `String "direct" -> Ok "direct"
          | `String "inherited" -> Ok "inherited"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      id : string;
      min_access_level : int option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      relation : Relation.t option; [@default None]
      search : string option; [@default None]
      with_custom_attributes : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/invited_groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("relation", Var (params.relation, Option (Array String)));
           ("search", Var (params.search, Option String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdIssuesEventableIdResourceMilestoneEvents = struct
  module Parameters = struct
    type t = {
      eventable_id : int;
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/issues/{eventable_id}/resource_milestone_events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("eventable_id", Var (params.eventable_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdIssuesEventableIdResourceMilestoneEventsEventId = struct
  module Parameters = struct
    type t = {
      event_id : string;
      eventable_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/issues/{eventable_id}/resource_milestone_events/{event_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("event_id", Var (params.event_id, String));
           ("eventable_id", Var (params.eventable_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdIssuesIssueIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      issue_iid : int;
      postapiv4projectsidissuesissueiidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdIssuesIssueIidAwardEmoji.t;
          [@key "postApiV4ProjectsIdIssuesIssueIidAwardEmoji"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("issue_iid", Var (params.issue_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdIssuesIssueIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : string;
      issue_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("issue_iid", Var (params.issue_iid, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdIssuesIssueIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      issue_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdIssuesIssueIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      issue_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdIssuesIssueIidLinks = struct
  module Parameters = struct
    type t = {
      id : string;
      issue_iid : int;
      postapiv4projectsidissuesissueiidlinks :
        Gitlabc_components.PostApiV4ProjectsIdIssuesIssueIidLinks.t;
          [@key "postApiV4ProjectsIdIssuesIssueIidLinks"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/links"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("issue_iid", Var (params.issue_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdIssuesIssueIidLinks = struct
  module Parameters = struct
    type t = {
      id : string;
      issue_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/links"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("issue_iid", Var (params.issue_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdIssuesIssueIidLinksIssueLinkId = struct
  module Parameters = struct
    type t = {
      id : string;
      issue_iid : int;
      issue_link_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/links/{issue_link_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("issue_iid", Var (params.issue_iid, Int));
           ("issue_link_id", Var (params.issue_link_id, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdIssuesIssueIidLinksIssueLinkId = struct
  module Parameters = struct
    type t = {
      id : string;
      issue_iid : int;
      issue_link_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/links/{issue_link_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("issue_iid", Var (params.issue_iid, Int));
           ("issue_link_id", Var (params.issue_link_id, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      issue_iid : int;
      note_id : int;
      postapiv4projectsidissuesissueiidnotesnoteidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmoji.t;
          [@key "postApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmoji"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      issue_iid : int;
      note_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      issue_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdIssuesIssueIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      issue_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/issues/{issue_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("issue_iid", Var (params.issue_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PatchApiV4ProjectsIdJobTokenScope = struct
  module Parameters = struct
    type t = {
      id : int;
      patchapiv4projectsidjobtokenscope : Gitlabc_components.PatchApiV4ProjectsIdJobTokenScope.t;
          [@key "patchApiV4ProjectsIdJobTokenScope"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module GetApiV4ProjectsIdJobTokenScope = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdJobTokenScopeAllowlist = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidjobtokenscopeallowlist :
        Gitlabc_components.PostApiV4ProjectsIdJobTokenScopeAllowlist.t;
          [@key "postApiV4ProjectsIdJobTokenScopeAllowlist"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/allowlist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdJobTokenScopeAllowlist = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/allowlist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdJobTokenScopeAllowlistTargetProjectId = struct
  module Parameters = struct
    type t = {
      id : int;
      target_project_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/allowlist/{target_project_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("target_project_id", Var (params.target_project_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdJobTokenScopeGroupsAllowlist = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidjobtokenscopegroupsallowlist :
        Gitlabc_components.PostApiV4ProjectsIdJobTokenScopeGroupsAllowlist.t;
          [@key "postApiV4ProjectsIdJobTokenScopeGroupsAllowlist"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/groups_allowlist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdJobTokenScopeGroupsAllowlist = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/groups_allowlist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdJobTokenScopeGroupsAllowlistTargetGroupId = struct
  module Parameters = struct
    type t = {
      id : int;
      target_group_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/job_token_scope/groups_allowlist/{target_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("target_group_id", Var (params.target_group_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdJobs = struct
  module Parameters = struct
    module Scope = struct
      module Items = struct
        let t_of_yojson = function
          | `String "created" -> Ok "created"
          | `String "waiting_for_resource" -> Ok "waiting_for_resource"
          | `String "preparing" -> Ok "preparing"
          | `String "waiting_for_callback" -> Ok "waiting_for_callback"
          | `String "pending" -> Ok "pending"
          | `String "running" -> Ok "running"
          | `String "success" -> Ok "success"
          | `String "failed" -> Ok "failed"
          | `String "canceling" -> Ok "canceling"
          | `String "canceled" -> Ok "canceled"
          | `String "skipped" -> Ok "skipped"
          | `String "manual" -> Ok "manual"
          | `String "scheduled" -> Ok "scheduled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option (Array String)));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdJobsArtifactsRefNameDownload = struct
  module Parameters = struct
    type t = {
      id : string;
      job : string;
      job_token : string option; [@default None]
      ref_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/artifacts/{ref_name}/download"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("ref_name", Var (params.ref_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job", Var (params.job, String)); ("job_token", Var (params.job_token, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdJobsArtifactsRefNameRaw_artifactPath = struct
  module Parameters = struct
    type t = {
      artifact_path : string;
      id : string;
      job : string;
      job_token : string option; [@default None]
      ref_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/artifacts/{ref_name}/raw/*artifact_path"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("ref_name", Var (params.ref_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("job", Var (params.job, String));
           ("artifact_path", Var (params.artifact_path, String));
           ("job_token", Var (params.job_token, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdJobsJobId = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdJobsJobIdArtifacts = struct
  module Parameters = struct
    type t = {
      id : string;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/artifacts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("job_id", Var (params.job_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdJobsJobIdArtifacts = struct
  module Parameters = struct
    type t = {
      id : string;
      job_id : int;
      job_token : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/artifacts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("job_id", Var (params.job_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_token", Var (params.job_token, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdJobsJobIdArtifacts_artifactPath = struct
  module Parameters = struct
    type t = {
      artifact_path : string;
      id : string;
      job_id : int;
      job_token : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/artifacts/*artifact_path"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("job_id", Var (params.job_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("artifact_path", Var (params.artifact_path, String));
           ("job_token", Var (params.job_token, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdJobsJobIdArtifactsKeep = struct
  module Parameters = struct
    type t = {
      id : string;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/artifacts/keep"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("job_id", Var (params.job_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdJobsJobIdCancel = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/cancel"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdJobsJobIdErase = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/erase"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdJobsJobIdPlay = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
      postapiv4projectsidjobsjobidplay : Gitlabc_components.PostApiV4ProjectsIdJobsJobIdPlay.t;
          [@key "postApiV4ProjectsIdJobsJobIdPlay"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/play"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdJobsJobIdRetry = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/retry"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdJobsJobIdTrace = struct
  module Parameters = struct
    type t = {
      id : int;
      job_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/jobs/{job_id}/trace"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("job_id", Var (params.job_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdLanguages = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/languages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMembers = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidmembers : Gitlabc_components.PostApiV4ProjectsIdMembers.t;
          [@key "postApiV4ProjectsIdMembers"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/members"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMembers = struct
  module Parameters = struct
    module Skip_users = struct
      type t = int list [@@deriving show, eq]
    end

    module User_ids = struct
      type t = int list [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      query : string option; [@default None]
      show_seat_info : bool option; [@default None]
      skip_users : Skip_users.t option; [@default None]
      user_ids : User_ids.t option; [@default None]
      with_saml_identity : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/members"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("query", Var (params.query, Option String));
           ("user_ids", Var (params.user_ids, Option (Array Int)));
           ("skip_users", Var (params.skip_users, Option (Array Int)));
           ("show_seat_info", Var (params.show_seat_info, Option Bool));
           ("with_saml_identity", Var (params.with_saml_identity, Option Bool));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMembersAll = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "awaiting" -> Ok "awaiting"
        | `String "active" -> Ok "active"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module User_ids = struct
      type t = int list [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      query : string option; [@default None]
      show_seat_info : bool option; [@default None]
      state : State.t option; [@default None]
      user_ids : User_ids.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/members/all"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("query", Var (params.query, Option String));
           ("user_ids", Var (params.user_ids, Option (Array Int)));
           ("show_seat_info", Var (params.show_seat_info, Option Bool));
           ("state", Var (params.state, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMembersAllUserId = struct
  module Parameters = struct
    type t = {
      id : string;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/members/all/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMembersUserId = struct
  module Parameters = struct
    type t = {
      id : string;
      skip_subresources : bool; [@default false]
      unassign_issuables : bool; [@default false]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/members/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("skip_subresources", Var (params.skip_subresources, Bool));
           ("unassign_issuables", Var (params.unassign_issuables, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMembersUserId = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidmembersuserid : Gitlabc_components.PutApiV4ProjectsIdMembersUserId.t;
          [@key "putApiV4ProjectsIdMembersUserId"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/members/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMembersUserId = struct
  module Parameters = struct
    type t = {
      id : string;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/members/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequests = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidmergerequests : Gitlabc_components.PostApiV4ProjectsIdMergeRequests.t;
          [@key "postApiV4ProjectsIdMergeRequests"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequests = struct
  module Parameters = struct
    module Approved = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Assignee_username = struct
      type t = string list [@@deriving show, eq]
    end

    module Iids = struct
      type t = int list [@@deriving show, eq]
    end

    module Labels = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_assignee_username_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_labels_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "label_priority" -> Ok "label_priority"
        | `String "milestone_due" -> Ok "milestone_due"
        | `String "popularity" -> Ok "popularity"
        | `String "priority" -> Ok "priority"
        | `String "title" -> Ok "title"
        | `String "updated_at" -> Ok "updated_at"
        | `String "merged_at" -> Ok "merged_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "created-by-me" -> Ok "created-by-me"
        | `String "assigned-to-me" -> Ok "assigned-to-me"
        | `String "created_by_me" -> Ok "created_by_me"
        | `String "assigned_to_me" -> Ok "assigned_to_me"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module State = struct
      let t_of_yojson = function
        | `String "opened" -> Ok "opened"
        | `String "closed" -> Ok "closed"
        | `String "locked" -> Ok "locked"
        | `String "merged" -> Ok "merged"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module View = struct
      let t_of_yojson = function
        | `String "simple" -> Ok "simple"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Wip = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      approved : Approved.t option; [@default None]
      approved_by_ids : string option; [@default None]
      approved_by_usernames : string option; [@default None]
      approver_ids : string option; [@default None]
      assignee_id : int option; [@default None]
      assignee_username : Assignee_username.t option; [@default None]
      author_id : int option; [@default None]
      author_username : string option; [@default None]
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      deployed_after : string option; [@default None]
      deployed_before : string option; [@default None]
      environment : string option; [@default None]
      id : string;
      iids : Iids.t option; [@default None]
      in_ : string option; [@default None] [@key "in"]
      labels : Labels.t option; [@default None]
      merge_user_id : int option; [@default None]
      merge_user_username : string option; [@default None]
      milestone : string option; [@default None]
      my_reaction_emoji : string option; [@default None]
      not_assignee_id_ : int option; [@default None] [@key "not[assignee_id]"]
      not_assignee_username_ : Not_assignee_username_.t option;
          [@default None] [@key "not[assignee_username]"]
      not_author_id_ : int option; [@default None] [@key "not[author_id]"]
      not_author_username_ : string option; [@default None] [@key "not[author_username]"]
      not_labels_ : Not_labels_.t option; [@default None] [@key "not[labels]"]
      not_milestone_ : string option; [@default None] [@key "not[milestone]"]
      not_my_reaction_emoji_ : string option; [@default None] [@key "not[my_reaction_emoji]"]
      not_reviewer_id_ : int option; [@default None] [@key "not[reviewer_id]"]
      not_reviewer_username_ : string option; [@default None] [@key "not[reviewer_username]"]
      order_by : Order_by.t; [@default "created_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      reviewer_id : int option; [@default None]
      reviewer_username : string option; [@default None]
      scope : Scope.t option; [@default None]
      search : string option; [@default None]
      sort : Sort.t; [@default "desc"]
      source_branch : string option; [@default None]
      source_project_id : int option; [@default None]
      state : State.t; [@default "all"]
      target_branch : string option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      view : View.t option; [@default None]
      wip : Wip.t option; [@default None]
      with_labels_details : bool; [@default false]
      with_merge_status_recheck : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("author_id", Var (params.author_id, Option Int));
           ("author_username", Var (params.author_username, Option String));
           ("assignee_id", Var (params.assignee_id, Option Int));
           ("assignee_username", Var (params.assignee_username, Option (Array String)));
           ("reviewer_username", Var (params.reviewer_username, Option String));
           ("labels", Var (params.labels, Option (Array String)));
           ("milestone", Var (params.milestone, Option String));
           ("my_reaction_emoji", Var (params.my_reaction_emoji, Option String));
           ("reviewer_id", Var (params.reviewer_id, Option Int));
           ("state", Var (params.state, String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("with_labels_details", Var (params.with_labels_details, Bool));
           ("with_merge_status_recheck", Var (params.with_merge_status_recheck, Bool));
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("view", Var (params.view, Option String));
           ("scope", Var (params.scope, Option String));
           ("source_branch", Var (params.source_branch, Option String));
           ("source_project_id", Var (params.source_project_id, Option Int));
           ("target_branch", Var (params.target_branch, Option String));
           ("search", Var (params.search, Option String));
           ("in", Var (params.in_, Option String));
           ("wip", Var (params.wip, Option String));
           ("not[author_id]", Var (params.not_author_id_, Option Int));
           ("not[author_username]", Var (params.not_author_username_, Option String));
           ("not[assignee_id]", Var (params.not_assignee_id_, Option Int));
           ("not[assignee_username]", Var (params.not_assignee_username_, Option (Array String)));
           ("not[reviewer_username]", Var (params.not_reviewer_username_, Option String));
           ("not[labels]", Var (params.not_labels_, Option (Array String)));
           ("not[milestone]", Var (params.not_milestone_, Option String));
           ("not[my_reaction_emoji]", Var (params.not_my_reaction_emoji_, Option String));
           ("not[reviewer_id]", Var (params.not_reviewer_id_, Option Int));
           ("deployed_before", Var (params.deployed_before, Option String));
           ("deployed_after", Var (params.deployed_after, Option String));
           ("environment", Var (params.environment, Option String));
           ("approved", Var (params.approved, Option String));
           ("merge_user_id", Var (params.merge_user_id, Option Int));
           ("merge_user_username", Var (params.merge_user_username, Option String));
           ("approver_ids", Var (params.approver_ids, Option String));
           ("approved_by_ids", Var (params.approved_by_ids, Option String));
           ("approved_by_usernames", Var (params.approved_by_usernames, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("iids", Var (params.iids, Option (Array Int)));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsEventableIdResourceMilestoneEvents = struct
  module Parameters = struct
    type t = {
      eventable_id : int;
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{eventable_id}/resource_milestone_events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("eventable_id", Var (params.eventable_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsEventableIdResourceMilestoneEventsEventId = struct
  module Parameters = struct
    type t = {
      event_id : string;
      eventable_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{eventable_id}/resource_milestone_events/{event_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("event_id", Var (params.event_id, String));
           ("eventable_id", Var (params.eventable_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      putapiv4projectsidmergerequestsmergerequestiid :
        Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIid.t;
          [@key "putApiV4ProjectsIdMergeRequestsMergeRequestIid"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      include_diverged_commits_count : bool option; [@default None]
      include_rebase_in_progress : bool option; [@default None]
      merge_request_iid : int;
      render_html : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("render_html", Var (params.render_html, Option Bool));
           ( "include_diverged_commits_count",
             Var (params.include_diverged_commits_count, Option Bool) );
           ("include_rebase_in_progress", Var (params.include_rebase_in_progress, Option Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidAddSpentTime = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidaddspenttime :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidAddSpentTime.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidAddSpentTime"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/add_spent_time"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidApprovalState = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approval_state"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidapprovals :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprove = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidapprove :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprove.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidApprove"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approve"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidCancelMergeWhenPipelineSucceeds = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end
    module Not_acceptable = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      | `Method_not_allowed
      | `Not_acceptable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
        ("406", fun _ -> Ok `Not_acceptable);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/cancel_merge_when_pipeline_succeeds"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidChanges = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/changes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("unidiff", Var (params.unidiff, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidClosesIssues = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/closes_issues"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    module Commits = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      commits : Commits.t;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("commits", Var (params.commits, Array String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidcontextcommits :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDiffs = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/diffs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("unidiff", Var (params.unidiff, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiiddraftnotes :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesBulkPublish = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/bulk_publish"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
      putapiv4projectsidmergerequestsmergerequestiiddraftnotesdraftnoteid :
        Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId.t;
          [@key "putApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteIdPublish = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}/publish"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidMerge = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      putapiv4projectsidmergerequestsmergerequestiidmerge :
        Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIidMerge.t;
          [@key "putApiV4ProjectsIdMergeRequestsMergeRequestIidMerge"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Method_not_allowed
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/merge"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidMergeRef = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end

    type t =
      [ `OK
      | `Bad_request
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/merge_ref"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      note_id : int;
      postapiv4projectsidmergerequestsmergerequestiidnotesnoteidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      note_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidParticipants = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/participants"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidpipelines :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Method_not_allowed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidRawDiffs = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/raw_diffs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidRebase = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      putapiv4projectsidmergerequestsmergerequestiidrebase :
        Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIidRebase.t;
          [@key "putApiV4ProjectsIdMergeRequestsMergeRequestIidRebase"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/rebase"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidRelatedIssues = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/related_issues"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidResetApprovals = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidResetSpentTime = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_spent_time"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidResetTimeEstimate = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_time_estimate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidReviewers = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reviewers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidTimeEstimate = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      postapiv4projectsidmergerequestsmergerequestiidtimeestimate :
        Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidTimeEstimate.t;
          [@key "postApiV4ProjectsIdMergeRequestsMergeRequestIidTimeEstimate"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/time_estimate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidTimeStats = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/time_stats"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidUnapprove = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/unapprove"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidVersions = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/versions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidVersionsVersionId = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      unidiff : bool; [@default false]
      version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/versions/{version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("version_id", Var (params.version_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("unidiff", Var (params.unidiff, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackages = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "name" -> Ok "name"
        | `String "version" -> Ok "version"
        | `String "type" -> Ok "type"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Package_type = struct
      let t_of_yojson = function
        | `String "maven" -> Ok "maven"
        | `String "npm" -> Ok "npm"
        | `String "conan" -> Ok "conan"
        | `String "nuget" -> Ok "nuget"
        | `String "pypi" -> Ok "pypi"
        | `String "composer" -> Ok "composer"
        | `String "generic" -> Ok "generic"
        | `String "golang" -> Ok "golang"
        | `String "debian" -> Ok "debian"
        | `String "rubygems" -> Ok "rubygems"
        | `String "helm" -> Ok "helm"
        | `String "terraform_module" -> Ok "terraform_module"
        | `String "rpm" -> Ok "rpm"
        | `String "ml_model" -> Ok "ml_model"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "default" -> Ok "default"
        | `String "hidden" -> Ok "hidden"
        | `String "processing" -> Ok "processing"
        | `String "error" -> Ok "error"
        | `String "pending_destruction" -> Ok "pending_destruction"
        | `String "deprecated" -> Ok "deprecated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      include_versionless : bool option; [@default None]
      order_by : Order_by.t; [@default "created_at"]
      package_name : string option; [@default None]
      package_type : Package_type.t option; [@default None]
      package_version : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "asc"]
      status : Status.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("package_type", Var (params.package_type, Option String));
           ("package_name", Var (params.package_name, Option String));
           ("package_version", Var (params.package_version, Option String));
           ("include_versionless", Var (params.include_versionless, Option Bool));
           ("status", Var (params.status, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesComposer = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpackagescomposer : Gitlabc_components.PostApiV4ProjectsIdPackagesComposer.t;
          [@key "postApiV4ProjectsIdPackagesComposer"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/composer"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesComposerArchives_packageName = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/composer/archives/*package_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("sha", Var (params.sha, String)); ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesConanV1ConansSearch = struct
  module Parameters = struct
    type t = {
      id : string;
      q : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v1/conans/search"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("q", Var (params.q, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  DeleteApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannel =
struct
  module Parameters = struct
    type t = {
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannel =
struct
  module Parameters = struct
    type t = {
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelDigest =
struct
  module Parameters = struct
    type t = {
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/digest"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelDownloadUrls =
struct
  module Parameters = struct
    type t = {
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/download_urls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelPackagesConanPackageReference =
struct
  module Parameters = struct
    type t = {
      conan_package_reference : string;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/packages/{conan_package_reference}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelPackagesConanPackageReferenceDigest =
struct
  module Parameters = struct
    type t = {
      conan_package_reference : string;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/packages/{conan_package_reference}/digest"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelPackagesConanPackageReferenceDownloadUrls =
struct
  module Parameters = struct
    type t = {
      conan_package_reference : string;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/packages/{conan_package_reference}/download_urls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  PostApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelPackagesConanPackageReferenceUploadUrls =
struct
  module Parameters = struct
    type t = {
      conan_package_reference : string;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/packages/{conan_package_reference}/upload_urls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module
  PostApiV4ProjectsIdPackagesConanV1ConansPackageNamePackageVersionPackageUsernamePackageChannelUploadUrls =
struct
  module Parameters = struct
    type t = {
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/conans/{package_name}/{package_version}/{package_username}/{package_channel}/upload_urls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module
  PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionExportFileName =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
      putapiv4projectsidpackagesconanv1filespackagenamepackageversionpackageusernamepackagechannelreciperevisionexportfilename :
        Gitlabc_components
        .PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionExportFileName
        .t;
          [@key
            "putApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionExportFileName"]
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/export/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module
  GetApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionExportFileName =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/export/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionExportFileNameAuthorize =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/export/{file_name}/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module
  PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionPackageConanPackageReferencePackageRevisionFileName =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      conan_package_reference : string;
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_revision : string;
      package_username : string;
      package_version : string;
      putapiv4projectsidpackagesconanv1filespackagenamepackageversionpackageusernamepackagechannelreciperevisionpackageconanpackagereferencepackagerevisionfilename :
        Gitlabc_components
        .PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionPackageConanPackageReferencePackageRevisionFileName
        .t;
          [@key
            "putApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionPackageConanPackageReferencePackageRevisionFileName"]
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/package/{conan_package_reference}/{package_revision}/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
           ("package_revision", Var (params.package_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module
  GetApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionPackageConanPackageReferencePackageRevisionFileName =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      conan_package_reference : string;
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_revision : string;
      package_username : string;
      package_version : string;
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/package/{conan_package_reference}/{package_revision}/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
           ("package_revision", Var (params.package_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module
  PutApiV4ProjectsIdPackagesConanV1FilesPackageNamePackageVersionPackageUsernamePackageChannelRecipeRevisionPackageConanPackageReferencePackageRevisionFileNameAuthorize =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      conan_package_reference : string;
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_revision : string;
      package_username : string;
      package_version : string;
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v1/files/{package_name}/{package_version}/{package_username}/{package_channel}/{recipe_revision}/package/{conan_package_reference}/{package_revision}/{file_name}/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("conan_package_reference", Var (params.conan_package_reference, String));
           ("package_revision", Var (params.package_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesConanV1Ping = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v1/ping"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesConanV1UsersAuthenticate = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v1/users/authenticate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesConanV1UsersCheckCredentials = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v1/users/check_credentials"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesConanV2ConansSearch = struct
  module Parameters = struct
    type t = {
      id : string;
      q : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v2/conans/search"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("q", Var (params.q, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesConanV2ConansPackageNamePackageVersionPackageUsernamePackageChannelRevisionsRecipeRevisionFilesFileName =
struct
  module Parameters = struct
    module File_name = struct
      let t_of_yojson = function
        | `String "conanfile.py" -> Ok "conanfile.py"
        | `String "conanmanifest.txt" -> Ok "conanmanifest.txt"
        | `String "conan_sources.tgz" -> Ok "conan_sources.tgz"
        | `String "conan_export.tgz" -> Ok "conan_export.tgz"
        | `String "conaninfo.txt" -> Ok "conaninfo.txt"
        | `String "conan_package.tgz" -> Ok "conan_package.tgz"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      file_name : File_name.t;
      id : string;
      package_channel : string;
      package_name : string;
      package_username : string;
      package_version : string;
      recipe_revision : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/conan/v2/conans/{package_name}/{package_version}/{package_username}/{package_channel}/revisions/{recipe_revision}/files/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_username", Var (params.package_username, String));
           ("package_channel", Var (params.package_channel, String));
           ("recipe_revision", Var (params.recipe_revision, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesConanV2UsersCheckCredentials = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/conan/v2/users/check_credentials"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionInrelease = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/dists/*distribution/InRelease"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionRelease = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/dists/*distribution/Release"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionReleaseGpg = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/dists/*distribution/Release.gpg"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionComponentBinary_ArchitecturePackages =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/binary-{architecture}/Packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesDebianDists_distributionComponentBinaryArchitectureByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/binary-{architecture}/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesDebianDists_distributionComponentDebianInstallerBinaryArchitecturePackages =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/debian-installer/binary-{architecture}/Packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4ProjectsIdPackagesDebianDists_distributionComponentDebianInstallerBinaryArchitectureByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/debian-installer/binary-{architecture}/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionComponentSourceSources = struct
  module Parameters = struct
    type t = {
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/source/Sources"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("component", Var (params.component, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianDists_distributionComponentSourceByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/dists/*distribution/{component}/source/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesDebianPoolDistributionLetterPackageNamePackageVersionFileName =
struct
  module Parameters = struct
    type t = {
      distribution : string;
      file_name : string;
      id : string;
      letter : string;
      package_name : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/debian/pool/{distribution}/{letter}/{package_name}/{package_version}/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("distribution", Var (params.distribution, String));
           ("letter", Var (params.letter, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesDebianFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      putapiv4projectsidpackagesdebianfilename :
        Gitlabc_components.PutApiV4ProjectsIdPackagesDebianFileName.t;
          [@key "putApiV4ProjectsIdPackagesDebianFileName"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesDebianFileNameAuthorize = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      putapiv4projectsidpackagesdebianfilenameauthorize :
        Gitlabc_components.PutApiV4ProjectsIdPackagesDebianFileNameAuthorize.t;
          [@key "putApiV4ProjectsIdPackagesDebianFileNameAuthorize"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/debian/{file_name}/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesGo_moduleName_vList = struct
  module Parameters = struct
    type t = {
      id : string;
      module_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/go/*module_name/@v/list"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("module_name", Var (params.module_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesGo_moduleName_vModuleVersionInfo = struct
  module Parameters = struct
    type t = {
      id : string;
      module_name : string;
      module_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/go/*module_name/@v/{module_version}.info"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("module_version", Var (params.module_version, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("module_name", Var (params.module_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesGo_moduleName_vModuleVersionMod = struct
  module Parameters = struct
    type t = {
      id : string;
      module_name : string;
      module_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/go/*module_name/@v/{module_version}.mod"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("module_version", Var (params.module_version, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("module_name", Var (params.module_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesGo_moduleName_vModuleVersionZip = struct
  module Parameters = struct
    type t = {
      id : string;
      module_name : string;
      module_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/go/*module_name/@v/{module_version}.zip"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String)); ("module_version", Var (params.module_version, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("module_name", Var (params.module_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesHelmApiChannelCharts = struct
  module Parameters = struct
    type t = {
      channel : string;
      id : int;
      postapiv4projectsidpackageshelmapichannelcharts :
        Gitlabc_components.PostApiV4ProjectsIdPackagesHelmApiChannelCharts.t;
          [@key "postApiV4ProjectsIdPackagesHelmApiChannelCharts"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/helm/api/{channel}/charts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("channel", Var (params.channel, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPackagesHelmApiChannelChartsAuthorize = struct
  module Parameters = struct
    type t = {
      channel : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/helm/api/{channel}/charts/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("channel", Var (params.channel, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesHelmChannelChartsFileNameTgz = struct
  module Parameters = struct
    type t = {
      channel : string;
      file_name : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/helm/{channel}/charts/{file_name}.tgz"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("channel", Var (params.channel, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesHelmChannelIndexYaml = struct
  module Parameters = struct
    type t = {
      channel : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/helm/{channel}/index.yaml"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("channel", Var (params.channel, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesMaven_pathFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      putapiv4projectsidpackagesmaven_pathfilename :
        Gitlabc_components.PutApiV4ProjectsIdPackagesMaven_pathFileName.t;
          [@key "putApiV4ProjectsIdPackagesMaven*pathFileName"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/maven/*path/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesMaven_pathFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      path : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Found = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Found
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("302", fun _ -> Ok `Found);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/maven/*path/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("path", Var (params.path, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesMaven_pathFileNameAuthorize = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      putapiv4projectsidpackagesmaven_pathfilenameauthorize :
        Gitlabc_components.PutApiV4ProjectsIdPackagesMaven_pathFileNameAuthorize.t;
          [@key "putApiV4ProjectsIdPackagesMaven*pathFileNameAuthorize"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/maven/*path/{file_name}/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesNpm_packageName = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Found = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Found
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("302", fun _ -> Ok `Found);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/*package_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNpm_packageName__fileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/*package_name/-/*file_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_name", Var (params.package_name, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesNpmNpmV1SecurityAdvisoriesBulk = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Temporary_redirect = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Temporary_redirect
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("307", fun _ -> Ok `Temporary_redirect);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/-/npm/v1/security/advisories/bulk"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPackagesNpmNpmV1SecurityAuditsQuick = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Temporary_redirect = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Temporary_redirect
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("307", fun _ -> Ok `Temporary_redirect);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/-/npm/v1/security/audits/quick"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesNpmPackage_packageNameDistTags = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/-/package/*package_name/dist-tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPackagesNpmPackage_packageNameDistTagsTag = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      tag : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/-/package/*package_name/dist-tags/{tag}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag", Var (params.tag, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdPackagesNpmPackage_packageNameDistTagsTag = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidpackagesnpmpackage_packagenamedisttagstag :
        Gitlabc_components.PutApiV4ProjectsIdPackagesNpmPackage_packageNameDistTagsTag.t;
          [@key "putApiV4ProjectsIdPackagesNpmPackage*packageNameDistTagsTag"]
      tag : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/-/package/*package_name/dist-tags/{tag}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag", Var (params.tag, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesNpmPackageName = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      putapiv4projectsidpackagesnpmpackagename :
        Gitlabc_components.PutApiV4ProjectsIdPackagesNpmPackageName.t;
          [@key "putApiV4ProjectsIdPackagesNpmPackageName"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/npm/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("package_name", Var (params.package_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesNuget = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidpackagesnuget : Gitlabc_components.PutApiV4ProjectsIdPackagesNuget.t;
          [@key "putApiV4ProjectsIdPackagesNuget"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module DeleteApiV4ProjectsIdPackagesNuget_packageName_packageVersion = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/*package_name/*package_version"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdPackagesNugetAuthorize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesNugetDownload_packageName_packageVersion_packageFilename = struct
  module Parameters = struct
    type t = {
      id : string;
      package_filename : string;
      package_name : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/nuget/download/*package_name/*package_version/*package_filename"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("package_filename", Var (params.package_filename, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetDownload_packageNameIndex = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/download/*package_name/index"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetIndex = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/index"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetMetadata_packageName_packageVersion = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/metadata/*package_name/*package_version"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetMetadata_packageNameIndex = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/metadata/*package_name/index"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetQuery = struct
  module Parameters = struct
    type t = {
      id : string;
      prerelease : bool; [@default true]
      q : string option; [@default None]
      skip : int; [@default 0]
      take : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/query"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, Option String));
           ("skip", Var (params.skip, Int));
           ("take", Var (params.take, Int));
           ("prerelease", Var (params.prerelease, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetSymbolfiles_fileName_signature_sameFileName = struct
  module Parameters = struct
    type t = {
      symbolchecksum : string; [@key "Symbolchecksum"]
      file_name : string;
      id : string;
      same_file_name : string;
      signature : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/symbolfiles/*file_name/*signature/*same_file_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("file_name", Var (params.file_name, String));
           ("signature", Var (params.signature, String));
           ("same_file_name", Var (params.same_file_name, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesNugetSymbolpackage = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidpackagesnugetsymbolpackage :
        Gitlabc_components.PutApiV4ProjectsIdPackagesNugetSymbolpackage.t;
          [@key "putApiV4ProjectsIdPackagesNugetSymbolpackage"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/symbolpackage"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesNugetSymbolpackageAuthorize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/symbolpackage/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesNugetV2 = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidpackagesnugetv2 : Gitlabc_components.PutApiV4ProjectsIdPackagesNugetV2.t;
          [@key "putApiV4ProjectsIdPackagesNugetV2"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/v2"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPackagesNugetV2 = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/v2"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesNugetV2_metadata = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/v2/$metadata"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesNugetV2Authorize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/nuget/v2/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdPackagesProtectionRules = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpackagesprotectionrules :
        Gitlabc_components.PostApiV4ProjectsIdPackagesProtectionRules.t;
          [@key "postApiV4ProjectsIdPackagesProtectionRules"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/protection/rules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesProtectionRules = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/protection/rules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PatchApiV4ProjectsIdPackagesProtectionRulesPackageProtectionRuleId = struct
  module Parameters = struct
    type t = {
      id : string;
      package_protection_rule_id : int;
      patchapiv4projectsidpackagesprotectionrulespackageprotectionruleid :
        Gitlabc_components.PatchApiV4ProjectsIdPackagesProtectionRulesPackageProtectionRuleId.t;
          [@key "patchApiV4ProjectsIdPackagesProtectionRulesPackageProtectionRuleId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/protection/rules/{package_protection_rule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_protection_rule_id", Var (params.package_protection_rule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module DeleteApiV4ProjectsIdPackagesProtectionRulesPackageProtectionRuleId = struct
  module Parameters = struct
    type t = {
      id : string;
      package_protection_rule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/protection/rules/{package_protection_rule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_protection_rule_id", Var (params.package_protection_rule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdPackagesPypi = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpackagespypi : Gitlabc_components.PostApiV4ProjectsIdPackagesPypi.t;
          [@key "postApiV4ProjectsIdPackagesPypi"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/pypi"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPackagesPypiAuthorize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/pypi/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesPypiFilesSha256_fileIdentifier = struct
  module Parameters = struct
    type t = {
      file_identifier : string;
      id : string;
      sha256 : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/pypi/files/{sha256}/*file_identifier"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha256", Var (params.sha256, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("file_identifier", Var (params.file_identifier, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesPypiSimple = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/pypi/simple"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesPypiSimple_packageName = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/pypi/simple/*package_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesRpm = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rpm"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesRpm_packageFileId_fileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      package_file_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rpm/*package_file_id/*file_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_file_id", Var (params.package_file_id, Int));
           ("file_name", Var (params.file_name, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesRpmAuthorize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rpm/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesRpmRepodata_fileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rpm/repodata/*file_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("file_name", Var (params.file_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesRubygemsApiV1Dependencies = struct
  module Parameters = struct
    module Gems = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      gems : Gems.t option; [@default None]
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/api/v1/dependencies"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("gems", Var (params.gems, Option (Array String))) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPackagesRubygemsApiV1Gems = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidpackagesrubygemsapiv1gems :
        Gitlabc_components.PostApiV4ProjectsIdPackagesRubygemsApiV1Gems.t;
          [@key "postApiV4ProjectsIdPackagesRubygemsApiV1Gems"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/api/v1/gems"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPackagesRubygemsApiV1GemsAuthorize = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/api/v1/gems/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPackagesRubygemsGemsFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/gems/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesRubygemsQuickMarshal48FileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/quick/Marshal.4.8/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesRubygemsFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/rubygems/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem = struct
  module Parameters = struct
    module Terraform_get = struct
      let t_of_yojson = function
        | `String "1" -> Ok "1"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      module_name : string;
      module_system : string;
      terraform_get : Terraform_get.t option; [@default None] [@key "terraform-get"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/terraform/modules/{module_name}/{module_system}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("module_name", Var (params.module_name, String));
           ("module_system", Var (params.module_system, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("terraform-get", Var (params.terraform_get, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem_moduleVersion = struct
  module Parameters = struct
    module Terraform_get = struct
      let t_of_yojson = function
        | `String "1" -> Ok "1"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      module_name : string;
      module_system : string;
      module_version : string;
      terraform_get : Terraform_get.t option; [@default None] [@key "terraform-get"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/terraform/modules/{module_name}/{module_system}/*module_version"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("module_name", Var (params.module_name, String));
           ("module_system", Var (params.module_system, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("module_version", Var (params.module_version, String));
           ("terraform-get", Var (params.terraform_get, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem_moduleVersionFile = struct
  module Parameters = struct
    type t = {
      file : string;
      id : string;
      module_name : string;
      module_system : string;
      module_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/packages/terraform/modules/{module_name}/{module_system}/*module_version/file"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("module_name", Var (params.module_name, String));
           ("module_system", Var (params.module_system, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem_moduleVersionFileAuthorize =
struct
  module Parameters = struct
    type t = {
      id : string;
      module_name : string;
      module_system : string;
      putapiv4projectsidpackagesterraformmodulesmodulenamemodulesystem_moduleversionfileauthorize :
        Gitlabc_components
        .PutApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem_moduleVersionFileAuthorize
        .t;
          [@key
            "putApiV4ProjectsIdPackagesTerraformModulesModuleNameModuleSystem*moduleVersionFileAuthorize"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url =
    "/api/v4/projects/{id}/packages/terraform/modules/{module_name}/{module_system}/*module_version/file/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("module_name", Var (params.module_name, String));
           ("module_system", Var (params.module_system, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module DeleteApiV4ProjectsIdPackagesPackageId = struct
  module Parameters = struct
    type t = {
      id : string;
      package_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/{package_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("package_id", Var (params.package_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPackagesPackageId = struct
  module Parameters = struct
    type t = {
      id : string;
      package_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/packages/{package_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("package_id", Var (params.package_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPackagesPackageIdPackageFiles = struct
  module Parameters = struct
    type t = {
      id : string;
      package_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/packages/{package_id}/package_files"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("package_id", Var (params.package_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPackagesPackageIdPackageFilesPackageFileId = struct
  module Parameters = struct
    type t = {
      id : string;
      package_file_id : int;
      package_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/{package_id}/package_files/{package_file_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("package_id", Var (params.package_id, Int));
           ("package_file_id", Var (params.package_file_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPackagesPackageIdPipelines = struct
  module Parameters = struct
    type t = {
      cursor : string option; [@default None]
      id : string;
      package_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/packages/{package_id}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("package_id", Var (params.package_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("cursor", Var (params.cursor, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PatchApiV4ProjectsIdPages = struct
  module Parameters = struct
    type t = {
      id : string;
      patchapiv4projectsidpages : Gitlabc_components.PatchApiV4ProjectsIdPages.t;
          [@key "patchApiV4ProjectsIdPages"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module DeleteApiV4ProjectsIdPages = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPages = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPagesDomains = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpagesdomains : Gitlabc_components.PostApiV4ProjectsIdPagesDomains.t;
          [@key "postApiV4ProjectsIdPagesDomains"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPagesDomains = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPagesDomainsDomain = struct
  module Parameters = struct
    type t = {
      domain : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains/{domain}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("domain", Var (params.domain, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdPagesDomainsDomain = struct
  module Parameters = struct
    type t = {
      domain : string;
      id : string;
      putapiv4projectsidpagesdomainsdomain :
        Gitlabc_components.PutApiV4ProjectsIdPagesDomainsDomain.t;
          [@key "putApiV4ProjectsIdPagesDomainsDomain"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains/{domain}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("domain", Var (params.domain, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPagesDomainsDomain = struct
  module Parameters = struct
    type t = {
      domain : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains/{domain}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("domain", Var (params.domain, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPagesDomainsDomainVerify = struct
  module Parameters = struct
    type t = {
      domain : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/pages/domains/{domain}/verify"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("domain", Var (params.domain, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPagesAccess = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/pages_access"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPipeline = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpipeline : Gitlabc_components.PostApiV4ProjectsIdPipeline.t;
          [@key "postApiV4ProjectsIdPipeline"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPipelineSchedules = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidpipelineschedules :
        Gitlabc_components.PostApiV4ProjectsIdPipelineSchedules.t;
          [@key "postApiV4ProjectsIdPipelineSchedules"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPipelineSchedules = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "inactive" -> Ok "inactive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("scope", Var (params.scope, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPipelineSchedulesPipelineScheduleId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdPipelineSchedulesPipelineScheduleId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
      putapiv4projectsidpipelineschedulespipelinescheduleid :
        Gitlabc_components.PutApiV4ProjectsIdPipelineSchedulesPipelineScheduleId.t;
          [@key "putApiV4ProjectsIdPipelineSchedulesPipelineScheduleId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPipelineSchedulesPipelineScheduleId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdPipelines = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdPlay = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/play"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdTakeOwnership = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/take_ownership"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariables = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_schedule_id : int;
      postapiv4projectsidpipelineschedulespipelinescheduleidvariables :
        Gitlabc_components.PostApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariables.t;
          [@key "postApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariables"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/variables"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariablesKey = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
      pipeline_schedule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Accepted
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
           ("key", Var (params.key, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariablesKey = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
      pipeline_schedule_id : int;
      putapiv4projectsidpipelineschedulespipelinescheduleidvariableskey :
        Gitlabc_components.PutApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariablesKey.t;
          [@key "putApiV4ProjectsIdPipelineSchedulesPipelineScheduleIdVariablesKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipeline_schedules/{pipeline_schedule_id}/variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("pipeline_schedule_id", Var (params.pipeline_schedule_id, Int));
           ("key", Var (params.key, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdPipelines = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "status" -> Ok "status"
        | `String "ref" -> Ok "ref"
        | `String "updated_at" -> Ok "updated_at"
        | `String "user_id" -> Ok "user_id"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "running" -> Ok "running"
        | `String "pending" -> Ok "pending"
        | `String "finished" -> Ok "finished"
        | `String "branches" -> Ok "branches"
        | `String "tags" -> Ok "tags"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Source = struct
      let t_of_yojson = function
        | `String "unknown" -> Ok "unknown"
        | `String "push" -> Ok "push"
        | `String "web" -> Ok "web"
        | `String "trigger" -> Ok "trigger"
        | `String "schedule" -> Ok "schedule"
        | `String "api" -> Ok "api"
        | `String "external" -> Ok "external"
        | `String "pipeline" -> Ok "pipeline"
        | `String "chat" -> Ok "chat"
        | `String "webide" -> Ok "webide"
        | `String "merge_request_event" -> Ok "merge_request_event"
        | `String "external_pull_request_event" -> Ok "external_pull_request_event"
        | `String "parent_pipeline" -> Ok "parent_pipeline"
        | `String "ondemand_dast_scan" -> Ok "ondemand_dast_scan"
        | `String "ondemand_dast_validation" -> Ok "ondemand_dast_validation"
        | `String "security_orchestration_policy" -> Ok "security_orchestration_policy"
        | `String "container_registry_push" -> Ok "container_registry_push"
        | `String "duo_workflow" -> Ok "duo_workflow"
        | `String "pipeline_execution_policy_schedule" -> Ok "pipeline_execution_policy_schedule"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      name : string option; [@default None]
      order_by : Order_by.t; [@default "id"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      ref_ : string option; [@default None] [@key "ref"]
      scope : Scope.t option; [@default None]
      sha : string option; [@default None]
      sort : Sort.t; [@default "desc"]
      source : Source.t option; [@default None]
      status : Status.t option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      username : string option; [@default None]
      yaml_errors : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("scope", Var (params.scope, Option String));
           ("status", Var (params.status, Option String));
           ("ref", Var (params.ref_, Option String));
           ("sha", Var (params.sha, Option String));
           ("yaml_errors", Var (params.yaml_errors, Option Bool));
           ("username", Var (params.username, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("source", Var (params.source, Option String));
           ("name", Var (params.name, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesLatest = struct
  module Parameters = struct
    type t = {
      id : string;
      ref_ : string option; [@default None] [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/latest"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("ref", Var (params.ref_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPipelinesPipelineId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end

    type t =
      [ `No_content
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPipelinesPipelineId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdBridges = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      pipeline_id : int;
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/bridges"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPipelinesPipelineIdCancel = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/cancel"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPipelinesPipelineIdJobs = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      include_retried : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      pipeline_id : int;
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("include_retried", Var (params.include_retried, Bool));
           ("scope", Var (params.scope, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPipelinesPipelineIdMetadata = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
      putapiv4projectsidpipelinespipelineidmetadata :
        Gitlabc_components.PutApiV4ProjectsIdPipelinesPipelineIdMetadata.t;
          [@key "putApiV4ProjectsIdPipelinesPipelineIdMetadata"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/metadata"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdPipelinesPipelineIdRetry = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/retry"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPipelinesPipelineIdTestReport = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/test_report"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdTestReportSummary = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/test_report_summary"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdVariables = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/variables"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdProtectedBranches = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidprotectedbranches :
        Gitlabc_components.PostApiV4ProjectsIdProtectedBranches.t;
          [@key "postApiV4ProjectsIdProtectedBranches"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_branches"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdProtectedBranches = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_branches"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("search", Var (params.search, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PatchApiV4ProjectsIdProtectedBranchesName = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
      patchapiv4projectsidprotectedbranchesname :
        Gitlabc_components.PatchApiV4ProjectsIdProtectedBranchesName.t;
          [@key "patchApiV4ProjectsIdProtectedBranchesName"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_branches/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("name", Var (params.name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module DeleteApiV4ProjectsIdProtectedBranchesName = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_branches/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("name", Var (params.name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdProtectedBranchesName = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_branches/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("name", Var (params.name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdProtectedTags = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidprotectedtags : Gitlabc_components.PostApiV4ProjectsIdProtectedTags.t;
          [@key "postApiV4ProjectsIdProtectedTags"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdProtectedTags = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/protected_tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdProtectedTagsName = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/protected_tags/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("name", Var (params.name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdProtectedTagsName = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/protected_tags/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("name", Var (params.name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsId_refRef_triggerPipeline = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsid_refref_triggerpipeline :
        Gitlabc_components.PostApiV4ProjectsId_refRef_triggerPipeline.t;
          [@key "postApiV4ProjectsId(refRef)triggerPipeline"]
      ref_ : string; [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/ref/{ref}/trigger/pipeline"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("ref", Var (params.ref_, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdRegistryProtectionRepositoryRules = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidregistryprotectionrepositoryrules :
        Gitlabc_components.PostApiV4ProjectsIdRegistryProtectionRepositoryRules.t;
          [@key "postApiV4ProjectsIdRegistryProtectionRepositoryRules"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/protection/repository/rules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRegistryProtectionRepositoryRules = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/protection/repository/rules"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PatchApiV4ProjectsIdRegistryProtectionRepositoryRulesProtectionRuleId = struct
  module Parameters = struct
    type t = {
      id : string;
      patchapiv4projectsidregistryprotectionrepositoryrulesprotectionruleid :
        Gitlabc_components.PatchApiV4ProjectsIdRegistryProtectionRepositoryRulesProtectionRuleId.t;
          [@key "patchApiV4ProjectsIdRegistryProtectionRepositoryRulesProtectionRuleId"]
      protection_rule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/protection/repository/rules/{protection_rule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("protection_rule_id", Var (params.protection_rule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module DeleteApiV4ProjectsIdRegistryProtectionRepositoryRulesProtectionRuleId = struct
  module Parameters = struct
    type t = {
      id : string;
      protection_rule_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/protection/repository/rules/{protection_rule_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("protection_rule_id", Var (params.protection_rule_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdRegistryRepositories = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      tags : bool; [@default false]
      tags_count : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("tags", Var (params.tags, Bool));
           ("tags_count", Var (params.tags_count, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRegistryRepositoriesRepositoryId = struct
  module Parameters = struct
    type t = {
      id : string;
      repository_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("repository_id", Var (params.repository_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module DeleteApiV4ProjectsIdRegistryRepositoriesRepositoryIdTags = struct
  module Parameters = struct
    type t = {
      id : string;
      keep_n : int option; [@default None]
      name_regex : string option; [@default None]
      name_regex_delete : string option; [@default None]
      name_regex_keep : string option; [@default None]
      older_than : string option; [@default None]
      repository_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories/{repository_id}/tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("repository_id", Var (params.repository_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("name_regex_delete", Var (params.name_regex_delete, Option String));
           ("name_regex", Var (params.name_regex, Option String));
           ("name_regex_keep", Var (params.name_regex_keep, Option String));
           ("keep_n", Var (params.keep_n, Option Int));
           ("older_than", Var (params.older_than, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdRegistryRepositoriesRepositoryIdTags = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      repository_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      | `Method_not_allowed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories/{repository_id}/tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("repository_id", Var (params.repository_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRegistryRepositoriesRepositoryIdTagsTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      repository_id : int;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories/{repository_id}/tags/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("repository_id", Var (params.repository_id, Int));
           ("tag_name", Var (params.tag_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdRegistryRepositoriesRepositoryIdTagsTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      repository_id : int;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/registry/repositories/{repository_id}/tags/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("repository_id", Var (params.repository_id, Int));
           ("tag_name", Var (params.tag_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRelationImports = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/relation-imports"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdReleases = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidreleases : Gitlabc_components.PostApiV4ProjectsIdReleases.t;
          [@key "postApiV4ProjectsIdReleases"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/releases"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdReleases = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "released_at" -> Ok "released_at"
        | `String "created_at" -> Ok "created_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      include_html_description : bool option; [@default None]
      order_by : Order_by.t; [@default "released_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "desc"]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/releases"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("include_html_description", Var (params.include_html_description, Option Bool));
           ("updated_before", Var (params.updated_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdReleasesTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdReleasesTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidreleasestagname : Gitlabc_components.PutApiV4ProjectsIdReleasesTagName.t;
          [@key "putApiV4ProjectsIdReleasesTagName"]
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdReleasesTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      include_html_description : bool option; [@default None]
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("include_html_description", Var (params.include_html_description, Option Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdReleasesTagNameAssetsLinks = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidreleasestagnameassetslinks :
        Gitlabc_components.PostApiV4ProjectsIdReleasesTagNameAssetsLinks.t;
          [@key "postApiV4ProjectsIdReleasesTagNameAssetsLinks"]
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/assets/links"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdReleasesTagNameAssetsLinks = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/assets/links"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdReleasesTagNameAssetsLinksLinkId = struct
  module Parameters = struct
    type t = {
      id : string;
      link_id : int;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end

    type t =
      [ `No_content
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("401", fun _ -> Ok `Unauthorized) ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/assets/links/{link_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("tag_name", Var (params.tag_name, String));
           ("link_id", Var (params.link_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdReleasesTagNameAssetsLinksLinkId = struct
  module Parameters = struct
    type t = {
      id : string;
      link_id : int;
      putapiv4projectsidreleasestagnameassetslinkslinkid :
        Gitlabc_components.PutApiV4ProjectsIdReleasesTagNameAssetsLinksLinkId.t;
          [@key "putApiV4ProjectsIdReleasesTagNameAssetsLinksLinkId"]
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/assets/links/{link_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("tag_name", Var (params.tag_name, String));
           ("link_id", Var (params.link_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdReleasesTagNameAssetsLinksLinkId = struct
  module Parameters = struct
    type t = {
      id : string;
      link_id : int;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/assets/links/{link_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("tag_name", Var (params.tag_name, String));
           ("link_id", Var (params.link_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdReleasesTagNameDownloads_directAssetPath = struct
  module Parameters = struct
    type t = {
      direct_asset_path : string;
      id : string;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/downloads/*direct_asset_path"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("direct_asset_path", Var (params.direct_asset_path, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdReleasesTagNameEvidence = struct
  module Parameters = struct
    type t = {
      id : int;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/releases/{tag_name}/evidence"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("tag_name", Var (params.tag_name, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdRemoteMirrors = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidremotemirrors : Gitlabc_components.PostApiV4ProjectsIdRemoteMirrors.t;
          [@key "postApiV4ProjectsIdRemoteMirrors"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRemoteMirrors = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRemoteMirrorsMirrorId = struct
  module Parameters = struct
    type t = {
      id : string;
      mirror_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors/{mirror_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("mirror_id", Var (params.mirror_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdRemoteMirrorsMirrorId = struct
  module Parameters = struct
    type t = {
      id : string;
      mirror_id : string;
      putapiv4projectsidremotemirrorsmirrorid :
        Gitlabc_components.PutApiV4ProjectsIdRemoteMirrorsMirrorId.t;
          [@key "putApiV4ProjectsIdRemoteMirrorsMirrorId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors/{mirror_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("mirror_id", Var (params.mirror_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdRemoteMirrorsMirrorId = struct
  module Parameters = struct
    type t = {
      id : string;
      mirror_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors/{mirror_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("mirror_id", Var (params.mirror_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRemoteMirrorsMirrorIdPublicKey = struct
  module Parameters = struct
    type t = {
      id : string;
      mirror_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors/{mirror_id}/public_key"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("mirror_id", Var (params.mirror_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRemoteMirrorsMirrorIdSync = struct
  module Parameters = struct
    type t = {
      id : string;
      mirror_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/remote_mirrors/{mirror_id}/sync"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("mirror_id", Var (params.mirror_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryArchive = struct
  module Parameters = struct
    module Exclude_paths = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      exclude_paths : Exclude_paths.t option; [@default None]
      format : string option; [@default None]
      id : string;
      include_lfs_blobs : bool; [@default true]
      path : string option; [@default None]
      sha : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/archive"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sha", Var (params.sha, Option String));
           ("format", Var (params.format, Option String));
           ("path", Var (params.path, Option String));
           ("include_lfs_blobs", Var (params.include_lfs_blobs, Bool));
           ("exclude_paths", Var (params.exclude_paths, Option (Array String)));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryBlobsSha = struct
  module Parameters = struct
    type t = {
      id : string;
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/blobs/{sha}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryBlobsShaRaw = struct
  module Parameters = struct
    type t = {
      id : string;
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/blobs/{sha}/raw"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRepositoryBranches = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorybranches :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryBranches.t;
          [@key "postApiV4ProjectsIdRepositoryBranches"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end

    type t =
      [ `Created
      | `Bad_request
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("400", fun _ -> Ok `Bad_request) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryBranches = struct
  module Parameters = struct
    module Sort = struct
      let t_of_yojson = function
        | `String "name_asc" -> Ok "name_asc"
        | `String "updated_asc" -> Ok "updated_asc"
        | `String "updated_desc" -> Ok "updated_desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      page_token : string option; [@default None]
      per_page : int; [@default 20]
      regex : string option; [@default None]
      search : string option; [@default None]
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("search", Var (params.search, Option String));
           ("regex", Var (params.regex, Option String));
           ("sort", Var (params.sort, Option String));
           ("page_token", Var (params.page_token, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRepositoryBranchesBranch = struct
  module Parameters = struct
    type t = {
      branch : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches/{branch}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("branch", Var (params.branch, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdRepositoryBranchesBranch = struct
  module Parameters = struct
    type t = {
      branch : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches/{branch}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("branch", Var (params.branch, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdRepositoryBranchesBranchProtect = struct
  module Parameters = struct
    type t = {
      branch : string;
      id : string;
      putapiv4projectsidrepositorybranchesbranchprotect :
        Gitlabc_components.PutApiV4ProjectsIdRepositoryBranchesBranchProtect.t;
          [@key "putApiV4ProjectsIdRepositoryBranchesBranchProtect"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches/{branch}/protect"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("branch", Var (params.branch, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdRepositoryBranchesBranchUnprotect = struct
  module Parameters = struct
    type t = {
      branch : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/branches/{branch}/unprotect"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("branch", Var (params.branch, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdRepositoryChangelog = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorychangelog :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryChangelog.t;
          [@key "postApiV4ProjectsIdRepositoryChangelog"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/changelog"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryChangelog = struct
  module Parameters = struct
    type t = {
      config_file : string option; [@default None]
      date : string option; [@default None]
      from : string option; [@default None]
      id : string;
      to_ : string option; [@default None] [@key "to"]
      trailer : string; [@default "Changelog"]
      version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/changelog"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("version", Var (params.version, String));
           ("from", Var (params.from, Option String));
           ("to", Var (params.to_, Option String));
           ("date", Var (params.date, Option String));
           ("trailer", Var (params.trailer, String));
           ("config_file", Var (params.config_file, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRepositoryCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorycommits :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryCommits.t;
          [@key "postApiV4ProjectsIdRepositoryCommits"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryCommits = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "default" -> Ok "default"
        | `String "topo" -> Ok "topo"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      all : bool option; [@default None]
      author : string option; [@default None]
      first_parent : bool option; [@default None]
      id : string;
      order : Order.t; [@default "default"]
      page : int; [@default 1]
      path : string option; [@default None]
      per_page : int; [@default 20]
      ref_name : string option; [@default None]
      since : string option; [@default None]
      trailers : bool; [@default false]
      until : string option; [@default None]
      with_stats : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("ref_name", Var (params.ref_name, Option String));
           ("since", Var (params.since, Option String));
           ("until", Var (params.until, Option String));
           ("path", Var (params.path, Option String));
           ("author", Var (params.author, Option String));
           ("all", Var (params.all, Option Bool));
           ("with_stats", Var (params.with_stats, Option Bool));
           ("first_parent", Var (params.first_parent, Option Bool));
           ("order", Var (params.order, String));
           ("trailers", Var (params.trailers, Bool));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsSha = struct
  module Parameters = struct
    type t = {
      id : string;
      sha : string;
      stats : bool; [@default true]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("stats", Var (params.stats, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRepositoryCommitsShaCherryPick = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorycommitsshacherrypick :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryCommitsShaCherryPick.t;
          [@key "postApiV4ProjectsIdRepositoryCommitsShaCherryPick"]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/cherry_pick"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdRepositoryCommitsShaComments = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorycommitsshacomments :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryCommitsShaComments.t;
          [@key "postApiV4ProjectsIdRepositoryCommitsShaComments"]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryCommitsShaComments = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsShaDiff = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sha : string;
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/diff"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("unidiff", Var (params.unidiff, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsShaMergeRequests = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/merge_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsShaRefs = struct
  module Parameters = struct
    module Type = struct
      let t_of_yojson = function
        | `String "branch" -> Ok "branch"
        | `String "tag" -> Ok "tag"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sha : string;
      type_ : Type.t; [@default "all"] [@key "type"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/refs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("type", Var (params.type_, String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRepositoryCommitsShaRevert = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorycommitssharevert :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryCommitsShaRevert.t;
          [@key "postApiV4ProjectsIdRepositoryCommitsShaRevert"]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/revert"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryCommitsShaSequence = struct
  module Parameters = struct
    type t = {
      first_parent : bool; [@default false]
      id : string;
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/sequence"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("first_parent", Var (params.first_parent, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsShaSignature = struct
  module Parameters = struct
    type t = {
      id : string;
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/signature"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCommitsShaStatuses = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "pipeline_id" -> Ok "pipeline_id"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      all : bool; [@default false]
      id : string;
      name : string option; [@default None]
      order_by : Order_by.t; [@default "id"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      pipeline_id : int option; [@default None]
      ref_ : string option; [@default None] [@key "ref"]
      sha : string;
      sort : Sort.t; [@default "asc"]
      stage : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/commits/{sha}/statuses"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("ref", Var (params.ref_, Option String));
           ("stage", Var (params.stage, Option String));
           ("name", Var (params.name, Option String));
           ("pipeline_id", Var (params.pipeline_id, Option Int));
           ("all", Var (params.all, Bool));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryCompare = struct
  module Parameters = struct
    type t = {
      from : string;
      from_project_id : int option; [@default None]
      id : string;
      straight : bool; [@default false]
      to_ : string; [@key "to"]
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/compare"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("from", Var (params.from, String));
           ("to", Var (params.to_, String));
           ("from_project_id", Var (params.from_project_id, Option Int));
           ("straight", Var (params.straight, Bool));
           ("unidiff", Var (params.unidiff, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryContributors = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "email" -> Ok "email"
        | `String "name" -> Ok "name"
        | `String "commits" -> Ok "commits"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      order_by : Order_by.t; [@default "commits"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      ref_ : string option; [@default None] [@key "ref"]
      sort : Sort.t; [@default "asc"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/contributors"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("ref", Var (params.ref_, Option String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRepositoryFilesFilePath = struct
  module Parameters = struct
    type t = {
      author_email : string option; [@default None]
      author_name : string option; [@default None]
      branch : string;
      commit_message : string;
      file_path : string;
      id : string;
      start_branch : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("branch", Var (params.branch, String));
           ("commit_message", Var (params.commit_message, String));
           ("start_branch", Var (params.start_branch, Option String));
           ("author_email", Var (params.author_email, Option String));
           ("author_name", Var (params.author_name, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdRepositoryFilesFilePath = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      postapiv4projectsidrepositoryfilesfilepath :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryFilesFilePath.t;
          [@key "postApiV4ProjectsIdRepositoryFilesFilePath"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PutApiV4ProjectsIdRepositoryFilesFilePath = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      putapiv4projectsidrepositoryfilesfilepath :
        Gitlabc_components.PutApiV4ProjectsIdRepositoryFilesFilePath.t;
          [@key "putApiV4ProjectsIdRepositoryFilesFilePath"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdRepositoryFilesFilePath = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      ref_ : string; [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("ref", Var (params.ref_, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryFilesFilePathBlame = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      range_end_ : int; [@key "range[end]"]
      range_start_ : int; [@key "range[start]"]
      ref_ : string; [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}/blame"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("ref", Var (params.ref_, String));
           ("range[start]", Var (params.range_start_, Int));
           ("range[end]", Var (params.range_end_, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryFilesFilePathRaw = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      lfs : bool; [@default false]
      ref_ : string option; [@default None] [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/files/{file_path}/raw"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_path", Var (params.file_path, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("ref", Var (params.ref_, Option String)); ("lfs", Var (params.lfs, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryMergeBase = struct
  module Parameters = struct
    module Refs = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      id : string;
      refs : Refs.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/merge_base"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("refs", Var (params.refs, Array String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRepositoryMergedBranches = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Not_found = struct end

    type t =
      [ `Accepted
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("202", fun _ -> Ok `Accepted); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/merged_branches"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdRepositorySubmodulesSubmodule = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidrepositorysubmodulessubmodule :
        Gitlabc_components.PutApiV4ProjectsIdRepositorySubmodulesSubmodule.t;
          [@key "putApiV4ProjectsIdRepositorySubmodulesSubmodule"]
      submodule : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/submodules/{submodule}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("submodule", Var (params.submodule, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdRepositoryTags = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorytags : Gitlabc_components.PostApiV4ProjectsIdRepositoryTags.t;
          [@key "postApiV4ProjectsIdRepositoryTags"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryTags = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "name" -> Ok "name"
        | `String "updated" -> Ok "updated"
        | `String "version" -> Ok "version"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      order_by : Order_by.t; [@default "updated"]
      page : int; [@default 1]
      page_token : string option; [@default None]
      per_page : int; [@default 20]
      search : string option; [@default None]
      sort : Sort.t; [@default "desc"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      | `Unprocessable_entity
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/tags"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sort", Var (params.sort, String));
           ("order_by", Var (params.order_by, String));
           ("search", Var (params.search, Option String));
           ("page_token", Var (params.page_token, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdRepositoryTagsTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/repository/tags/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdRepositoryTagsTagName = struct
  module Parameters = struct
    type t = {
      id : string;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/tags/{tag_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryTagsTagNameSignature = struct
  module Parameters = struct
    type t = {
      id : string;
      tag_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/repository/tags/{tag_name}/signature"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag_name", Var (params.tag_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryTree = struct
  module Parameters = struct
    module Pagination = struct
      let t_of_yojson = function
        | `String "legacy" -> Ok "legacy"
        | `String "keyset" -> Ok "keyset"
        | `String "none" -> Ok "none"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      page_token : string option; [@default None]
      pagination : Pagination.t; [@default "legacy"]
      path : string option; [@default None]
      per_page : int; [@default 20]
      recursive : bool; [@default false]
      ref_ : string option; [@default None] [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository/tree"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("ref", Var (params.ref_, Option String));
           ("path", Var (params.path, Option String));
           ("recursive", Var (params.recursive, Bool));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("pagination", Var (params.pagination, String));
           ("page_token", Var (params.page_token, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRepositorySize = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/repository_size"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdRepositoryStorageMoves = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrepositorystoragemoves :
        Gitlabc_components.PostApiV4ProjectsIdRepositoryStorageMoves.t;
          [@key "postApiV4ProjectsIdRepositoryStorageMoves"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/repository_storage_moves"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRepositoryStorageMoves = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository_storage_moves"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdRepositoryStorageMovesRepositoryStorageMoveId = struct
  module Parameters = struct
    type t = {
      id : string;
      repository_storage_move_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/repository_storage_moves/{repository_storage_move_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("repository_storage_move_id", Var (params.repository_storage_move_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdResourceGroups = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/resource_groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdResourceGroupsKey = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
      putapiv4projectsidresourcegroupskey : Gitlabc_components.PutApiV4ProjectsIdResourceGroupsKey.t;
          [@key "putApiV4ProjectsIdResourceGroupsKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/resource_groups/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdResourceGroupsKey = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/resource_groups/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdResourceGroupsKeyUpcomingJobs = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/resource_groups/{key}/upcoming_jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRestore = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdRunners = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidrunners : Gitlabc_components.PostApiV4ProjectsIdRunners.t;
          [@key "postApiV4ProjectsIdRunners"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdRunners = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "specific" -> Ok "specific"
        | `String "shared" -> Ok "shared"
        | `String "instance_type" -> Ok "instance_type"
        | `String "group_type" -> Ok "group_type"
        | `String "project_type" -> Ok "project_type"
        | `String "active" -> Ok "active"
        | `String "paused" -> Ok "paused"
        | `String "online" -> Ok "online"
        | `String "offline" -> Ok "offline"
        | `String "never_contacted" -> Ok "never_contacted"
        | `String "stale" -> Ok "stale"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "paused" -> Ok "paused"
        | `String "online" -> Ok "online"
        | `String "offline" -> Ok "offline"
        | `String "never_contacted" -> Ok "never_contacted"
        | `String "stale" -> Ok "stale"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Tag_list = struct
      type t = string list [@@deriving show, eq]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "instance_type" -> Ok "instance_type"
        | `String "group_type" -> Ok "group_type"
        | `String "project_type" -> Ok "project_type"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      paused : bool option; [@default None]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
      status : Status.t option; [@default None]
      tag_list : Tag_list.t option; [@default None]
      type_ : Type.t option; [@default None] [@key "type"]
      version_prefix : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
           ("type", Var (params.type_, Option String));
           ("paused", Var (params.paused, Option Bool));
           ("status", Var (params.status, Option String));
           ("tag_list", Var (params.tag_list, Option (Array String)));
           ("version_prefix", Var (params.version_prefix, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdRunnersResetRegistrationToken = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/runners/reset_registration_token"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdRunnersRunnerId = struct
  module Parameters = struct
    type t = {
      id : string;
      runner_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("runner_id", Var (params.runner_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdSecureFiles = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidsecurefiles : Gitlabc_components.PostApiV4ProjectsIdSecureFiles.t;
          [@key "postApiV4ProjectsIdSecureFiles"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end

    type t =
      [ `Created
      | `Bad_request
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("400", fun _ -> Ok `Bad_request) ]
  end

  let url = "/api/v4/projects/{id}/secure_files"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdSecureFiles = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/secure_files"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdSecureFilesSecureFileId = struct
  module Parameters = struct
    type t = {
      id : string;
      secure_file_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/secure_files/{secure_file_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("secure_file_id", Var (params.secure_file_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdSecureFilesSecureFileId = struct
  module Parameters = struct
    type t = {
      id : int;
      secure_file_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/secure_files/{secure_file_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("secure_file_id", Var (params.secure_file_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdSecureFilesSecureFileIdDownload = struct
  module Parameters = struct
    type t = {
      id : string;
      secure_file_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/secure_files/{secure_file_id}/download"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("secure_file_id", Var (params.secure_file_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdServices = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/services"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdServicesAppleAppStore = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesappleappstore :
        Gitlabc_components.PutApiV4ProjectsIdServicesAppleAppStore.t;
          [@key "putApiV4ProjectsIdServicesAppleAppStore"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/apple-app-store"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesAsana = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesasana : Gitlabc_components.PutApiV4ProjectsIdServicesAsana.t;
          [@key "putApiV4ProjectsIdServicesAsana"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/asana"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesAssembla = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesassembla : Gitlabc_components.PutApiV4ProjectsIdServicesAssembla.t;
          [@key "putApiV4ProjectsIdServicesAssembla"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/assembla"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesBamboo = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesbamboo : Gitlabc_components.PutApiV4ProjectsIdServicesBamboo.t;
          [@key "putApiV4ProjectsIdServicesBamboo"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/bamboo"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesBugzilla = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesbugzilla : Gitlabc_components.PutApiV4ProjectsIdServicesBugzilla.t;
          [@key "putApiV4ProjectsIdServicesBugzilla"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/bugzilla"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesBuildkite = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesbuildkite : Gitlabc_components.PutApiV4ProjectsIdServicesBuildkite.t;
          [@key "putApiV4ProjectsIdServicesBuildkite"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/buildkite"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesCampfire = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicescampfire : Gitlabc_components.PutApiV4ProjectsIdServicesCampfire.t;
          [@key "putApiV4ProjectsIdServicesCampfire"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/campfire"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesClickup = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesclickup : Gitlabc_components.PutApiV4ProjectsIdServicesClickup.t;
          [@key "putApiV4ProjectsIdServicesClickup"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/clickup"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesConfluence = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesconfluence :
        Gitlabc_components.PutApiV4ProjectsIdServicesConfluence.t;
          [@key "putApiV4ProjectsIdServicesConfluence"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/confluence"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesCustomIssueTracker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicescustomissuetracker :
        Gitlabc_components.PutApiV4ProjectsIdServicesCustomIssueTracker.t;
          [@key "putApiV4ProjectsIdServicesCustomIssueTracker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/custom-issue-tracker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesDatadog = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesdatadog : Gitlabc_components.PutApiV4ProjectsIdServicesDatadog.t;
          [@key "putApiV4ProjectsIdServicesDatadog"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/datadog"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesDiffblueCover = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesdiffbluecover :
        Gitlabc_components.PutApiV4ProjectsIdServicesDiffblueCover.t;
          [@key "putApiV4ProjectsIdServicesDiffblueCover"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/diffblue-cover"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesDiscord = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesdiscord : Gitlabc_components.PutApiV4ProjectsIdServicesDiscord.t;
          [@key "putApiV4ProjectsIdServicesDiscord"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/discord"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesDroneCi = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesdroneci : Gitlabc_components.PutApiV4ProjectsIdServicesDroneCi.t;
          [@key "putApiV4ProjectsIdServicesDroneCi"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/drone-ci"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesEmailsOnPush = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesemailsonpush :
        Gitlabc_components.PutApiV4ProjectsIdServicesEmailsOnPush.t;
          [@key "putApiV4ProjectsIdServicesEmailsOnPush"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/emails-on-push"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesEwm = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesewm : Gitlabc_components.PutApiV4ProjectsIdServicesEwm.t;
          [@key "putApiV4ProjectsIdServicesEwm"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/ewm"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesExternalWiki = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesexternalwiki :
        Gitlabc_components.PutApiV4ProjectsIdServicesExternalWiki.t;
          [@key "putApiV4ProjectsIdServicesExternalWiki"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/external-wiki"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGitGuardian = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgitguardian :
        Gitlabc_components.PutApiV4ProjectsIdServicesGitGuardian.t;
          [@key "putApiV4ProjectsIdServicesGitGuardian"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/git-guardian"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGithub = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgithub : Gitlabc_components.PutApiV4ProjectsIdServicesGithub.t;
          [@key "putApiV4ProjectsIdServicesGithub"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/github"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGitlabSlackApplication = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgitlabslackapplication :
        Gitlabc_components.PutApiV4ProjectsIdServicesGitlabSlackApplication.t;
          [@key "putApiV4ProjectsIdServicesGitlabSlackApplication"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/gitlab-slack-application"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGoogleCloudPlatformArtifactRegistry = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgooglecloudplatformartifactregistry :
        Gitlabc_components.PutApiV4ProjectsIdServicesGoogleCloudPlatformArtifactRegistry.t;
          [@key "putApiV4ProjectsIdServicesGoogleCloudPlatformArtifactRegistry"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/google-cloud-platform-artifact-registry"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGoogleCloudPlatformWorkloadIdentityFederation = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgooglecloudplatformworkloadidentityfederation :
        Gitlabc_components.PutApiV4ProjectsIdServicesGoogleCloudPlatformWorkloadIdentityFederation.t;
          [@key "putApiV4ProjectsIdServicesGoogleCloudPlatformWorkloadIdentityFederation"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/google-cloud-platform-workload-identity-federation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesGooglePlay = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesgoogleplay :
        Gitlabc_components.PutApiV4ProjectsIdServicesGooglePlay.t;
          [@key "putApiV4ProjectsIdServicesGooglePlay"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/google-play"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesHangoutsChat = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidserviceshangoutschat :
        Gitlabc_components.PutApiV4ProjectsIdServicesHangoutsChat.t;
          [@key "putApiV4ProjectsIdServicesHangoutsChat"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/hangouts-chat"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesHarbor = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesharbor : Gitlabc_components.PutApiV4ProjectsIdServicesHarbor.t;
          [@key "putApiV4ProjectsIdServicesHarbor"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/harbor"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesIrker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesirker : Gitlabc_components.PutApiV4ProjectsIdServicesIrker.t;
          [@key "putApiV4ProjectsIdServicesIrker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/irker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesJenkins = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesjenkins : Gitlabc_components.PutApiV4ProjectsIdServicesJenkins.t;
          [@key "putApiV4ProjectsIdServicesJenkins"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/jenkins"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesJira = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesjira : Gitlabc_components.PutApiV4ProjectsIdServicesJira.t;
          [@key "putApiV4ProjectsIdServicesJira"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/jira"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesJiraCloudApp = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesjiracloudapp :
        Gitlabc_components.PutApiV4ProjectsIdServicesJiraCloudApp.t;
          [@key "putApiV4ProjectsIdServicesJiraCloudApp"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/jira-cloud-app"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesMatrix = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmatrix : Gitlabc_components.PutApiV4ProjectsIdServicesMatrix.t;
          [@key "putApiV4ProjectsIdServicesMatrix"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/matrix"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesMattermost = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmattermost :
        Gitlabc_components.PutApiV4ProjectsIdServicesMattermost.t;
          [@key "putApiV4ProjectsIdServicesMattermost"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/mattermost"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesMattermostSlashCommands = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmattermostslashcommands :
        Gitlabc_components.PutApiV4ProjectsIdServicesMattermostSlashCommands.t;
          [@key "putApiV4ProjectsIdServicesMattermostSlashCommands"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/mattermost-slash-commands"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdServicesMattermostSlashCommandsTrigger = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidservicesmattermostslashcommandstrigger :
        Gitlabc_components.PostApiV4ProjectsIdServicesMattermostSlashCommandsTrigger.t;
          [@key "postApiV4ProjectsIdServicesMattermostSlashCommandsTrigger"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/services/mattermost_slash_commands/trigger"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PutApiV4ProjectsIdServicesMicrosoftTeams = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmicrosoftteams :
        Gitlabc_components.PutApiV4ProjectsIdServicesMicrosoftTeams.t;
          [@key "putApiV4ProjectsIdServicesMicrosoftTeams"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/microsoft-teams"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesMockCi = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmockci : Gitlabc_components.PutApiV4ProjectsIdServicesMockCi.t;
          [@key "putApiV4ProjectsIdServicesMockCi"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/mock-ci"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesMockMonitoring = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesmockmonitoring :
        Gitlabc_components.PutApiV4ProjectsIdServicesMockMonitoring.t;
          [@key "putApiV4ProjectsIdServicesMockMonitoring"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/mock-monitoring"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPackagist = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicespackagist : Gitlabc_components.PutApiV4ProjectsIdServicesPackagist.t;
          [@key "putApiV4ProjectsIdServicesPackagist"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/packagist"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPhorge = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesphorge : Gitlabc_components.PutApiV4ProjectsIdServicesPhorge.t;
          [@key "putApiV4ProjectsIdServicesPhorge"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/phorge"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPipelinesEmail = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicespipelinesemail :
        Gitlabc_components.PutApiV4ProjectsIdServicesPipelinesEmail.t;
          [@key "putApiV4ProjectsIdServicesPipelinesEmail"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/pipelines-email"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPivotaltracker = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicespivotaltracker :
        Gitlabc_components.PutApiV4ProjectsIdServicesPivotaltracker.t;
          [@key "putApiV4ProjectsIdServicesPivotaltracker"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/pivotaltracker"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPumble = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicespumble : Gitlabc_components.PutApiV4ProjectsIdServicesPumble.t;
          [@key "putApiV4ProjectsIdServicesPumble"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/pumble"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesPushover = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicespushover : Gitlabc_components.PutApiV4ProjectsIdServicesPushover.t;
          [@key "putApiV4ProjectsIdServicesPushover"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/pushover"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesRedmine = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesredmine : Gitlabc_components.PutApiV4ProjectsIdServicesRedmine.t;
          [@key "putApiV4ProjectsIdServicesRedmine"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/redmine"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesSlack = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesslack : Gitlabc_components.PutApiV4ProjectsIdServicesSlack.t;
          [@key "putApiV4ProjectsIdServicesSlack"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/slack"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesSlackSlashCommands = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesslackslashcommands :
        Gitlabc_components.PutApiV4ProjectsIdServicesSlackSlashCommands.t;
          [@key "putApiV4ProjectsIdServicesSlackSlashCommands"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/slack-slash-commands"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdServicesSlackSlashCommandsTrigger = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidservicesslackslashcommandstrigger :
        Gitlabc_components.PostApiV4ProjectsIdServicesSlackSlashCommandsTrigger.t;
          [@key "postApiV4ProjectsIdServicesSlackSlashCommandsTrigger"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/services/slack_slash_commands/trigger"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PutApiV4ProjectsIdServicesSquashTm = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicessquashtm : Gitlabc_components.PutApiV4ProjectsIdServicesSquashTm.t;
          [@key "putApiV4ProjectsIdServicesSquashTm"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/squash-tm"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesTeamcity = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesteamcity : Gitlabc_components.PutApiV4ProjectsIdServicesTeamcity.t;
          [@key "putApiV4ProjectsIdServicesTeamcity"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/teamcity"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesTelegram = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicestelegram : Gitlabc_components.PutApiV4ProjectsIdServicesTelegram.t;
          [@key "putApiV4ProjectsIdServicesTelegram"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/telegram"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesUnifyCircuit = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesunifycircuit :
        Gitlabc_components.PutApiV4ProjectsIdServicesUnifyCircuit.t;
          [@key "putApiV4ProjectsIdServicesUnifyCircuit"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/unify-circuit"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesWebexTeams = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidserviceswebexteams :
        Gitlabc_components.PutApiV4ProjectsIdServicesWebexTeams.t;
          [@key "putApiV4ProjectsIdServicesWebexTeams"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/webex-teams"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesYoutrack = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidservicesyoutrack : Gitlabc_components.PutApiV4ProjectsIdServicesYoutrack.t;
          [@key "putApiV4ProjectsIdServicesYoutrack"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/youtrack"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdServicesZentao = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidserviceszentao : Gitlabc_components.PutApiV4ProjectsIdServicesZentao.t;
          [@key "putApiV4ProjectsIdServicesZentao"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/services/zentao"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module DeleteApiV4ProjectsIdServicesSlug = struct
  module Parameters = struct
    module Slug = struct
      let t_of_yojson = function
        | `String "apple-app-store" -> Ok "apple-app-store"
        | `String "asana" -> Ok "asana"
        | `String "assembla" -> Ok "assembla"
        | `String "bamboo" -> Ok "bamboo"
        | `String "bugzilla" -> Ok "bugzilla"
        | `String "buildkite" -> Ok "buildkite"
        | `String "campfire" -> Ok "campfire"
        | `String "confluence" -> Ok "confluence"
        | `String "custom-issue-tracker" -> Ok "custom-issue-tracker"
        | `String "datadog" -> Ok "datadog"
        | `String "diffblue-cover" -> Ok "diffblue-cover"
        | `String "discord" -> Ok "discord"
        | `String "drone-ci" -> Ok "drone-ci"
        | `String "emails-on-push" -> Ok "emails-on-push"
        | `String "external-wiki" -> Ok "external-wiki"
        | `String "gitlab-slack-application" -> Ok "gitlab-slack-application"
        | `String "google-play" -> Ok "google-play"
        | `String "hangouts-chat" -> Ok "hangouts-chat"
        | `String "harbor" -> Ok "harbor"
        | `String "irker" -> Ok "irker"
        | `String "jenkins" -> Ok "jenkins"
        | `String "jira" -> Ok "jira"
        | `String "jira-cloud-app" -> Ok "jira-cloud-app"
        | `String "matrix" -> Ok "matrix"
        | `String "mattermost-slash-commands" -> Ok "mattermost-slash-commands"
        | `String "slack-slash-commands" -> Ok "slack-slash-commands"
        | `String "packagist" -> Ok "packagist"
        | `String "phorge" -> Ok "phorge"
        | `String "pipelines-email" -> Ok "pipelines-email"
        | `String "pivotaltracker" -> Ok "pivotaltracker"
        | `String "pumble" -> Ok "pumble"
        | `String "pushover" -> Ok "pushover"
        | `String "redmine" -> Ok "redmine"
        | `String "ewm" -> Ok "ewm"
        | `String "youtrack" -> Ok "youtrack"
        | `String "clickup" -> Ok "clickup"
        | `String "slack" -> Ok "slack"
        | `String "microsoft-teams" -> Ok "microsoft-teams"
        | `String "mattermost" -> Ok "mattermost"
        | `String "teamcity" -> Ok "teamcity"
        | `String "telegram" -> Ok "telegram"
        | `String "unify-circuit" -> Ok "unify-circuit"
        | `String "webex-teams" -> Ok "webex-teams"
        | `String "zentao" -> Ok "zentao"
        | `String "squash-tm" -> Ok "squash-tm"
        | `String "github" -> Ok "github"
        | `String "git-guardian" -> Ok "git-guardian"
        | `String "google-cloud-platform-artifact-registry" ->
            Ok "google-cloud-platform-artifact-registry"
        | `String "google-cloud-platform-workload-identity-federation" ->
            Ok "google-cloud-platform-workload-identity-federation"
        | `String "mock-ci" -> Ok "mock-ci"
        | `String "mock-monitoring" -> Ok "mock-monitoring"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : int;
      slug : Slug.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/services/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdServicesSlug = struct
  module Parameters = struct
    module Slug = struct
      let t_of_yojson = function
        | `String "apple-app-store" -> Ok "apple-app-store"
        | `String "asana" -> Ok "asana"
        | `String "assembla" -> Ok "assembla"
        | `String "bamboo" -> Ok "bamboo"
        | `String "bugzilla" -> Ok "bugzilla"
        | `String "buildkite" -> Ok "buildkite"
        | `String "campfire" -> Ok "campfire"
        | `String "confluence" -> Ok "confluence"
        | `String "custom-issue-tracker" -> Ok "custom-issue-tracker"
        | `String "datadog" -> Ok "datadog"
        | `String "diffblue-cover" -> Ok "diffblue-cover"
        | `String "discord" -> Ok "discord"
        | `String "drone-ci" -> Ok "drone-ci"
        | `String "emails-on-push" -> Ok "emails-on-push"
        | `String "external-wiki" -> Ok "external-wiki"
        | `String "gitlab-slack-application" -> Ok "gitlab-slack-application"
        | `String "google-play" -> Ok "google-play"
        | `String "hangouts-chat" -> Ok "hangouts-chat"
        | `String "harbor" -> Ok "harbor"
        | `String "irker" -> Ok "irker"
        | `String "jenkins" -> Ok "jenkins"
        | `String "jira" -> Ok "jira"
        | `String "jira-cloud-app" -> Ok "jira-cloud-app"
        | `String "matrix" -> Ok "matrix"
        | `String "mattermost-slash-commands" -> Ok "mattermost-slash-commands"
        | `String "slack-slash-commands" -> Ok "slack-slash-commands"
        | `String "packagist" -> Ok "packagist"
        | `String "phorge" -> Ok "phorge"
        | `String "pipelines-email" -> Ok "pipelines-email"
        | `String "pivotaltracker" -> Ok "pivotaltracker"
        | `String "pumble" -> Ok "pumble"
        | `String "pushover" -> Ok "pushover"
        | `String "redmine" -> Ok "redmine"
        | `String "ewm" -> Ok "ewm"
        | `String "youtrack" -> Ok "youtrack"
        | `String "clickup" -> Ok "clickup"
        | `String "slack" -> Ok "slack"
        | `String "microsoft-teams" -> Ok "microsoft-teams"
        | `String "mattermost" -> Ok "mattermost"
        | `String "teamcity" -> Ok "teamcity"
        | `String "telegram" -> Ok "telegram"
        | `String "unify-circuit" -> Ok "unify-circuit"
        | `String "webex-teams" -> Ok "webex-teams"
        | `String "zentao" -> Ok "zentao"
        | `String "squash-tm" -> Ok "squash-tm"
        | `String "github" -> Ok "github"
        | `String "git-guardian" -> Ok "git-guardian"
        | `String "google-cloud-platform-artifact-registry" ->
            Ok "google-cloud-platform-artifact-registry"
        | `String "google-cloud-platform-workload-identity-federation" ->
            Ok "google-cloud-platform-workload-identity-federation"
        | `String "mock-ci" -> Ok "mock-ci"
        | `String "mock-monitoring" -> Ok "mock-monitoring"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : int;
      slug : Slug.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/services/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdShare = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidshare : Gitlabc_components.PostApiV4ProjectsIdShare.t;
          [@key "postApiV4ProjectsIdShare"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/share"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdShareGroupId = struct
  module Parameters = struct
    type t = {
      group_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/share/{group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("group_id", Var (params.group_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdShareLocations = struct
  module Parameters = struct
    type t = {
      id : int;
      search : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/share_locations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("search", Var (params.search, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdSnapshot = struct
  module Parameters = struct
    type t = {
      id : int;
      wiki : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized) ]
  end

  let url = "/api/v4/projects/{id}/snapshot"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("wiki", Var (params.wiki, Option Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdSnippets = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidsnippets : Gitlabc_components.PostApiV4ProjectsIdSnippets.t;
          [@key "postApiV4ProjectsIdSnippets"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdSnippets = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdSnippetsSnippetId = struct
  module Parameters = struct
    type t = {
      id : string;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdSnippetsSnippetId = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidsnippetssnippetid :
        Gitlabc_components.PutApiV4ProjectsIdSnippetsSnippetId.t;
          [@key "putApiV4ProjectsIdSnippetsSnippetId"]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdSnippetsSnippetId = struct
  module Parameters = struct
    type t = {
      id : string;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdSnippetsSnippetIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidsnippetssnippetidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdSnippetsSnippetIdAwardEmoji.t;
          [@key "postApiV4ProjectsIdSnippetsSnippetIdAwardEmoji"]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdSnippetsSnippetIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdSnippetsSnippetIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdSnippetsSnippetIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdSnippetsSnippetIdFilesRefFilePathRaw = struct
  module Parameters = struct
    type t = {
      file_path : string;
      id : string;
      ref_ : string; [@key "ref"]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/files/{ref}/{file_path}/raw"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("file_path", Var (params.file_path, String));
           ("ref", Var (params.ref_, String));
           ("snippet_id", Var (params.snippet_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      note_id : int;
      postapiv4projectsidsnippetssnippetidnotesnoteidawardemoji :
        Gitlabc_components.PostApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji.t;
          [@key "postApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji"]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      note_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      note_id : int;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      note_id : int;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("snippet_id", Var (params.snippet_id, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdSnippetsSnippetIdRaw = struct
  module Parameters = struct
    type t = {
      id : string;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/raw"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdSnippetsSnippetIdUserAgentDetail = struct
  module Parameters = struct
    type t = {
      id : string;
      snippet_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/snippets/{snippet_id}/user_agent_detail"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("snippet_id", Var (params.snippet_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdStar = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_modified = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Not_modified
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("304", fun _ -> Ok `Not_modified);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/star"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdStarrers = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/starrers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("search", Var (params.search, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdStatistics = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/statistics"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdStatusesSha = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidstatusessha : Gitlabc_components.PostApiV4ProjectsIdStatusesSha.t;
          [@key "postApiV4ProjectsIdStatusesSha"]
      sha : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/statuses/{sha}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdStorage = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/storage"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdTemplatesType = struct
  module Parameters = struct
    module Type = struct
      let t_of_yojson = function
        | `String "dockerfiles" -> Ok "dockerfiles"
        | `String "gitignores" -> Ok "gitignores"
        | `String "gitlab_ci_ymls" -> Ok "gitlab_ci_ymls"
        | `String "licenses" -> Ok "licenses"
        | `String "issues" -> Ok "issues"
        | `String "merge_requests" -> Ok "merge_requests"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      type_ : Type.t; [@key "type"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/templates/{type}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("type", Var (params.type_, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdTemplatesTypeName = struct
  module Parameters = struct
    module Type = struct
      let t_of_yojson = function
        | `String "dockerfiles" -> Ok "dockerfiles"
        | `String "gitignores" -> Ok "gitignores"
        | `String "gitlab_ci_ymls" -> Ok "gitlab_ci_ymls"
        | `String "licenses" -> Ok "licenses"
        | `String "issues" -> Ok "issues"
        | `String "merge_requests" -> Ok "merge_requests"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      fullname : string option; [@default None]
      id : string;
      name : string;
      project : string option; [@default None]
      source_template_project_id : int option; [@default None]
      type_ : Type.t; [@key "type"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/templates/{type}/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("type", Var (params.type_, String));
           ("name", Var (params.name, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("source_template_project_id", Var (params.source_template_project_id, Option Int));
           ("project", Var (params.project, Option String));
           ("fullname", Var (params.fullname, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdTerraformStateNameVersionsSerial = struct
  module Parameters = struct
    type t = {
      id : string;
      name : int;
      serial : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/terraform/state/{name}/versions/{serial}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("name", Var (params.name, Int));
           ("serial", Var (params.serial, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdTerraformStateNameVersionsSerial = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string;
      serial : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/terraform/state/{name}/versions/{serial}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("name", Var (params.name, String));
           ("serial", Var (params.serial, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdTransfer = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidtransfer : Gitlabc_components.PutApiV4ProjectsIdTransfer.t;
          [@key "putApiV4ProjectsIdTransfer"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/transfer"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdTransferLocations = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/transfer_locations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("search", Var (params.search, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdTriggers = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidtriggers : Gitlabc_components.PostApiV4ProjectsIdTriggers.t;
          [@key "postApiV4ProjectsIdTriggers"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/triggers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdTriggers = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/triggers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdTriggersTriggerId = struct
  module Parameters = struct
    type t = {
      id : string;
      trigger_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/triggers/{trigger_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("trigger_id", Var (params.trigger_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdTriggersTriggerId = struct
  module Parameters = struct
    type t = {
      id : string;
      putapiv4projectsidtriggerstriggerid :
        Gitlabc_components.PutApiV4ProjectsIdTriggersTriggerId.t;
          [@key "putApiV4ProjectsIdTriggersTriggerId"]
      trigger_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/triggers/{trigger_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("trigger_id", Var (params.trigger_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdTriggersTriggerId = struct
  module Parameters = struct
    type t = {
      id : string;
      trigger_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/triggers/{trigger_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("trigger_id", Var (params.trigger_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdUnarchive = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/projects/{id}/unarchive"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdUnstar = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_modified = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Not_modified
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("304", fun _ -> Ok `Not_modified);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/unstar"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdUploads = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsiduploads : Gitlabc_components.PostApiV4ProjectsIdUploads.t;
          [@key "postApiV4ProjectsIdUploads"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/uploads"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdUploads = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/uploads"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdUploadsAuthorize = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/uploads/authorize"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdUploadsSecretFilename = struct
  module Parameters = struct
    type t = {
      filename : string;
      id : int;
      secret : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/uploads/{secret}/{filename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("secret", Var (params.secret, String));
           ("filename", Var (params.filename, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdUploadsSecretFilename = struct
  module Parameters = struct
    type t = {
      filename : string;
      id : int;
      secret : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/uploads/{secret}/{filename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("secret", Var (params.secret, String));
           ("filename", Var (params.filename, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdUploadsUploadId = struct
  module Parameters = struct
    type t = {
      id : int;
      upload_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/uploads/{upload_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("upload_id", Var (params.upload_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdUploadsUploadId = struct
  module Parameters = struct
    type t = {
      id : int;
      upload_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/uploads/{upload_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("upload_id", Var (params.upload_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdUsers = struct
  module Parameters = struct
    module Skip_users = struct
      type t = int list [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      skip_users : Skip_users.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("search", Var (params.search, Option String));
           ("skip_users", Var (params.skip_users, Option (Array Int)));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdVariables = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidvariables : Gitlabc_components.PostApiV4ProjectsIdVariables.t;
          [@key "postApiV4ProjectsIdVariables"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end

    type t =
      [ `Created
      | `Bad_request
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("400", fun _ -> Ok `Bad_request) ]
  end

  let url = "/api/v4/projects/{id}/variables"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdVariables = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/variables"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdVariablesKey = struct
  module Parameters = struct
    type t = {
      filter_environment_scope_ : string option; [@default None] [@key "filter[environment_scope]"]
      id : string;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("filter[environment_scope]", Var (params.filter_environment_scope_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdVariablesKey = struct
  module Parameters = struct
    type t = {
      id : string;
      key : string;
      putapiv4projectsidvariableskey : Gitlabc_components.PutApiV4ProjectsIdVariablesKey.t;
          [@key "putApiV4ProjectsIdVariablesKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdVariablesKey = struct
  module Parameters = struct
    type t = {
      filter_environment_scope_ : string option; [@default None] [@key "filter[environment_scope]"]
      id : string;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("key", Var (params.key, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("filter[environment_scope]", Var (params.filter_environment_scope_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdWikis = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidwikis : Gitlabc_components.PostApiV4ProjectsIdWikis.t;
          [@key "postApiV4ProjectsIdWikis"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdWikis = struct
  module Parameters = struct
    type t = {
      id : int;
      with_content : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("with_content", Var (params.with_content, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdWikisAttachments = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidwikisattachments : Gitlabc_components.PostApiV4ProjectsIdWikisAttachments.t;
          [@key "postApiV4ProjectsIdWikisAttachments"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis/attachments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      slug : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidwikisslug : Gitlabc_components.PutApiV4ProjectsIdWikisSlug.t;
          [@key "putApiV4ProjectsIdWikisSlug"]
      slug : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("slug", Var (params.slug, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      render_html : bool; [@default false]
      slug : string;
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("version", Var (params.version, Option String));
           ("render_html", Var (params.render_html, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsProjectIdPackagesNugetV2Findpackagesbyid____ = struct
  module Parameters = struct
    type t = {
      id : string;
      project_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{project_id}/packages/nuget/v2/FindPackagesById\\(\\)"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("project_id", Var (params.project_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsProjectIdPackagesNugetV2Packages____ = struct
  module Parameters = struct
    type t = {
      filter_ : string; [@key "$filter"]
      project_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{project_id}/packages/nuget/v2/Packages\\(\\)"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("project_id", Var (params.project_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("$filter", Var (params.filter_, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end
