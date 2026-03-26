module Primary = struct
  module Failure_reason = struct
    let t_of_yojson = function
      | `String "actions_workflow_run_failed" -> Ok `Actions_workflow_run_failed
      | `String "internal_error" -> Ok `Internal_error
      | `String "no_repos_queried" -> Ok `No_repos_queried
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Actions_workflow_run_failed -> `String "actions_workflow_run_failed"
      | `Internal_error -> `String "internal_error"
      | `No_repos_queried -> `String "no_repos_queried"

    type t =
      ([ `Actions_workflow_run_failed
       | `Internal_error
       | `No_repos_queried
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Scanned_repositories = struct
    module Items = struct
      module Primary = struct
        type t = {
          analysis_status : Githubc2_components_code_scanning_variant_analysis_status.t;
          artifact_size_in_bytes : int option; [@default None]
          failure_message : string option; [@default None]
          repository : Githubc2_components_code_scanning_variant_analysis_repository.t;
          result_count : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Skipped_repositories = struct
    module Primary = struct
      module Not_found_repos = struct
        module Primary = struct
          module Repository_full_names = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            repository_count : int;
            repository_full_names : Repository_full_names.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        access_mismatch_repos :
          Githubc2_components_code_scanning_variant_analysis_skipped_repo_group.t;
        no_codeql_db_repos :
          Githubc2_components_code_scanning_variant_analysis_skipped_repo_group.t;
        not_found_repos : Not_found_repos.t;
        over_limit_repos : Githubc2_components_code_scanning_variant_analysis_skipped_repo_group.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "cancelled" -> Ok `Cancelled
      | `String "failed" -> Ok `Failed
      | `String "in_progress" -> Ok `In_progress
      | `String "succeeded" -> Ok `Succeeded
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Cancelled -> `String "cancelled"
      | `Failed -> `String "failed"
      | `In_progress -> `String "in_progress"
      | `Succeeded -> `String "succeeded"

    type t =
      ([ `Cancelled
       | `Failed
       | `In_progress
       | `Succeeded
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actions_workflow_run_id : int option; [@default None]
    actor : Githubc2_components_simple_user.t;
    completed_at : string option; [@default None]
    controller_repo : Githubc2_components_simple_repository.t;
    created_at : string option; [@default None]
    failure_reason : Failure_reason.t option; [@default None]
    id : int;
    query_language : Githubc2_components_code_scanning_variant_analysis_language.t;
    query_pack_url : string;
    scanned_repositories : Scanned_repositories.t option; [@default None]
    skipped_repositories : Skipped_repositories.t option; [@default None]
    status : Status_.t;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
