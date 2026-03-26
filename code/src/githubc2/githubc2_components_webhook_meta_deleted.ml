module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "deleted" -> Ok `Deleted
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Deleted -> `String "deleted"

    type t = ([ `Deleted ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Hook_ = struct
    module Primary = struct
      module Config = struct
        module Primary = struct
          module Content_type = struct
            let t_of_yojson = function
              | `String "form" -> Ok `Form
              | `String "json" -> Ok `Json
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Form -> `String "form"
              | `Json -> `String "json"

            type t =
              ([ `Form
               | `Json
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
            | `String "*" -> Ok `V__
            | `String "branch_protection_rule" -> Ok `Branch_protection_rule
            | `String "check_run" -> Ok `Check_run
            | `String "check_suite" -> Ok `Check_suite
            | `String "code_scanning_alert" -> Ok `Code_scanning_alert
            | `String "commit_comment" -> Ok `Commit_comment
            | `String "create" -> Ok `Create
            | `String "delete" -> Ok `Delete
            | `String "deploy_key" -> Ok `Deploy_key
            | `String "deployment" -> Ok `Deployment
            | `String "deployment_status" -> Ok `Deployment_status
            | `String "discussion" -> Ok `Discussion
            | `String "discussion_comment" -> Ok `Discussion_comment
            | `String "fork" -> Ok `Fork
            | `String "gollum" -> Ok `Gollum
            | `String "issue_comment" -> Ok `Issue_comment
            | `String "issues" -> Ok `Issues
            | `String "label" -> Ok `Label
            | `String "member" -> Ok `Member
            | `String "membership" -> Ok `Membership
            | `String "meta" -> Ok `Meta
            | `String "milestone" -> Ok `Milestone
            | `String "org_block" -> Ok `Org_block
            | `String "organization" -> Ok `Organization
            | `String "package" -> Ok `Package
            | `String "page_build" -> Ok `Page_build
            | `String "project" -> Ok `Project
            | `String "project_card" -> Ok `Project_card
            | `String "project_column" -> Ok `Project_column
            | `String "projects_v2_item" -> Ok `Projects_v2_item
            | `String "public" -> Ok `Public
            | `String "pull_request" -> Ok `Pull_request
            | `String "pull_request_review" -> Ok `Pull_request_review
            | `String "pull_request_review_comment" -> Ok `Pull_request_review_comment
            | `String "pull_request_review_thread" -> Ok `Pull_request_review_thread
            | `String "push" -> Ok `Push
            | `String "registry_package" -> Ok `Registry_package
            | `String "release" -> Ok `Release
            | `String "repository" -> Ok `Repository
            | `String "repository_dispatch" -> Ok `Repository_dispatch
            | `String "repository_import" -> Ok `Repository_import
            | `String "repository_vulnerability_alert" -> Ok `Repository_vulnerability_alert
            | `String "secret_scanning_alert" -> Ok `Secret_scanning_alert
            | `String "secret_scanning_alert_location" -> Ok `Secret_scanning_alert_location
            | `String "security_and_analysis" -> Ok `Security_and_analysis
            | `String "star" -> Ok `Star
            | `String "status" -> Ok `Status
            | `String "team" -> Ok `Team
            | `String "team_add" -> Ok `Team_add
            | `String "watch" -> Ok `Watch
            | `String "workflow_job" -> Ok `Workflow_job
            | `String "workflow_run" -> Ok `Workflow_run
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `V__ -> `String "*"
            | `Branch_protection_rule -> `String "branch_protection_rule"
            | `Check_run -> `String "check_run"
            | `Check_suite -> `String "check_suite"
            | `Code_scanning_alert -> `String "code_scanning_alert"
            | `Commit_comment -> `String "commit_comment"
            | `Create -> `String "create"
            | `Delete -> `String "delete"
            | `Deploy_key -> `String "deploy_key"
            | `Deployment -> `String "deployment"
            | `Deployment_status -> `String "deployment_status"
            | `Discussion -> `String "discussion"
            | `Discussion_comment -> `String "discussion_comment"
            | `Fork -> `String "fork"
            | `Gollum -> `String "gollum"
            | `Issue_comment -> `String "issue_comment"
            | `Issues -> `String "issues"
            | `Label -> `String "label"
            | `Member -> `String "member"
            | `Membership -> `String "membership"
            | `Meta -> `String "meta"
            | `Milestone -> `String "milestone"
            | `Org_block -> `String "org_block"
            | `Organization -> `String "organization"
            | `Package -> `String "package"
            | `Page_build -> `String "page_build"
            | `Project -> `String "project"
            | `Project_card -> `String "project_card"
            | `Project_column -> `String "project_column"
            | `Projects_v2_item -> `String "projects_v2_item"
            | `Public -> `String "public"
            | `Pull_request -> `String "pull_request"
            | `Pull_request_review -> `String "pull_request_review"
            | `Pull_request_review_comment -> `String "pull_request_review_comment"
            | `Pull_request_review_thread -> `String "pull_request_review_thread"
            | `Push -> `String "push"
            | `Registry_package -> `String "registry_package"
            | `Release -> `String "release"
            | `Repository -> `String "repository"
            | `Repository_dispatch -> `String "repository_dispatch"
            | `Repository_import -> `String "repository_import"
            | `Repository_vulnerability_alert -> `String "repository_vulnerability_alert"
            | `Secret_scanning_alert -> `String "secret_scanning_alert"
            | `Secret_scanning_alert_location -> `String "secret_scanning_alert_location"
            | `Security_and_analysis -> `String "security_and_analysis"
            | `Star -> `String "star"
            | `Status -> `String "status"
            | `Team -> `String "team"
            | `Team_add -> `String "team_add"
            | `Watch -> `String "watch"
            | `Workflow_job -> `String "workflow_job"
            | `Workflow_run -> `String "workflow_run"

          type t =
            ([ `V__
             | `Branch_protection_rule
             | `Check_run
             | `Check_suite
             | `Code_scanning_alert
             | `Commit_comment
             | `Create
             | `Delete
             | `Deploy_key
             | `Deployment
             | `Deployment_status
             | `Discussion
             | `Discussion_comment
             | `Fork
             | `Gollum
             | `Issue_comment
             | `Issues
             | `Label
             | `Member
             | `Membership
             | `Meta
             | `Milestone
             | `Org_block
             | `Organization
             | `Package
             | `Page_build
             | `Project
             | `Project_card
             | `Project_column
             | `Projects_v2_item
             | `Public
             | `Pull_request
             | `Pull_request_review
             | `Pull_request_review_comment
             | `Pull_request_review_thread
             | `Push
             | `Registry_package
             | `Release
             | `Repository
             | `Repository_dispatch
             | `Repository_import
             | `Repository_vulnerability_alert
             | `Secret_scanning_alert
             | `Secret_scanning_alert_location
             | `Security_and_analysis
             | `Star
             | `Status
             | `Team
             | `Team_add
             | `Watch
             | `Workflow_job
             | `Workflow_run
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
