module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "deleted" -> Ok "deleted"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Hook_ = struct
    module Primary = struct
      module Config = struct
        module Primary = struct
          module Content_type = struct
            let t_of_yojson = function
              | `String "json" -> Ok "json"
              | `String "form" -> Ok "form"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            content_type : Content_type.t;
            insecure_ssl : string;
            secret : string option; [@default None]
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Events = struct
        module Items = struct
          let t_of_yojson = function
            | `String "*" -> Ok "*"
            | `String "branch_protection_rule" -> Ok "branch_protection_rule"
            | `String "check_run" -> Ok "check_run"
            | `String "check_suite" -> Ok "check_suite"
            | `String "code_scanning_alert" -> Ok "code_scanning_alert"
            | `String "commit_comment" -> Ok "commit_comment"
            | `String "create" -> Ok "create"
            | `String "delete" -> Ok "delete"
            | `String "deployment" -> Ok "deployment"
            | `String "deployment_status" -> Ok "deployment_status"
            | `String "deploy_key" -> Ok "deploy_key"
            | `String "discussion" -> Ok "discussion"
            | `String "discussion_comment" -> Ok "discussion_comment"
            | `String "fork" -> Ok "fork"
            | `String "gollum" -> Ok "gollum"
            | `String "issues" -> Ok "issues"
            | `String "issue_comment" -> Ok "issue_comment"
            | `String "label" -> Ok "label"
            | `String "member" -> Ok "member"
            | `String "membership" -> Ok "membership"
            | `String "meta" -> Ok "meta"
            | `String "milestone" -> Ok "milestone"
            | `String "organization" -> Ok "organization"
            | `String "org_block" -> Ok "org_block"
            | `String "package" -> Ok "package"
            | `String "page_build" -> Ok "page_build"
            | `String "project" -> Ok "project"
            | `String "project_card" -> Ok "project_card"
            | `String "project_column" -> Ok "project_column"
            | `String "public" -> Ok "public"
            | `String "pull_request" -> Ok "pull_request"
            | `String "pull_request_review" -> Ok "pull_request_review"
            | `String "pull_request_review_comment" -> Ok "pull_request_review_comment"
            | `String "pull_request_review_thread" -> Ok "pull_request_review_thread"
            | `String "push" -> Ok "push"
            | `String "registry_package" -> Ok "registry_package"
            | `String "release" -> Ok "release"
            | `String "repository" -> Ok "repository"
            | `String "repository_import" -> Ok "repository_import"
            | `String "repository_vulnerability_alert" -> Ok "repository_vulnerability_alert"
            | `String "secret_scanning_alert" -> Ok "secret_scanning_alert"
            | `String "secret_scanning_alert_location" -> Ok "secret_scanning_alert_location"
            | `String "security_and_analysis" -> Ok "security_and_analysis"
            | `String "star" -> Ok "star"
            | `String "status" -> Ok "status"
            | `String "team" -> Ok "team"
            | `String "team_add" -> Ok "team_add"
            | `String "watch" -> Ok "watch"
            | `String "workflow_job" -> Ok "workflow_job"
            | `String "workflow_run" -> Ok "workflow_run"
            | `String "repository_dispatch" -> Ok "repository_dispatch"
            | `String "projects_v2_item" -> Ok "projects_v2_item"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        active : bool;
        config : Config.t;
        created_at : string;
        events : Events.t;
        id : int;
        name : string;
        type_ : string; [@key "type"]
        updated_at : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    hook : Hook_.t;
    hook_id : int;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_nullable_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
