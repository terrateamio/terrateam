module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "requested" -> Ok `Requested
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Requested -> `String "requested"

    type t = ([ `Requested ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Check_suite_ = struct
    module Primary = struct
      module App = struct
        module Primary = struct
          module Events = struct
            module Items = struct
              let t_of_yojson = function
                | `String "branch_protection_rule" -> Ok `Branch_protection_rule
                | `String "check_run" -> Ok `Check_run
                | `String "check_suite" -> Ok `Check_suite
                | `String "code_scanning_alert" -> Ok `Code_scanning_alert
                | `String "commit_comment" -> Ok `Commit_comment
                | `String "content_reference" -> Ok `Content_reference
                | `String "create" -> Ok `Create
                | `String "delete" -> Ok `Delete
                | `String "deploy_key" -> Ok `Deploy_key
                | `String "deployment" -> Ok `Deployment
                | `String "deployment_review" -> Ok `Deployment_review
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
                | `String "merge_group" -> Ok `Merge_group
                | `String "merge_queue_entry" -> Ok `Merge_queue_entry
                | `String "milestone" -> Ok `Milestone
                | `String "org_block" -> Ok `Org_block
                | `String "organization" -> Ok `Organization
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
                | `String "secret_scanning_alert" -> Ok `Secret_scanning_alert
                | `String "secret_scanning_alert_location" -> Ok `Secret_scanning_alert_location
                | `String "security_and_analysis" -> Ok `Security_and_analysis
                | `String "star" -> Ok `Star
                | `String "status" -> Ok `Status
                | `String "team" -> Ok `Team
                | `String "team_add" -> Ok `Team_add
                | `String "watch" -> Ok `Watch
                | `String "workflow_dispatch" -> Ok `Workflow_dispatch
                | `String "workflow_job" -> Ok `Workflow_job
                | `String "workflow_run" -> Ok `Workflow_run
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              let t_to_yojson = function
                | `Branch_protection_rule -> `String "branch_protection_rule"
                | `Check_run -> `String "check_run"
                | `Check_suite -> `String "check_suite"
                | `Code_scanning_alert -> `String "code_scanning_alert"
                | `Commit_comment -> `String "commit_comment"
                | `Content_reference -> `String "content_reference"
                | `Create -> `String "create"
                | `Delete -> `String "delete"
                | `Deploy_key -> `String "deploy_key"
                | `Deployment -> `String "deployment"
                | `Deployment_review -> `String "deployment_review"
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
                | `Merge_group -> `String "merge_group"
                | `Merge_queue_entry -> `String "merge_queue_entry"
                | `Milestone -> `String "milestone"
                | `Org_block -> `String "org_block"
                | `Organization -> `String "organization"
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
                | `Secret_scanning_alert -> `String "secret_scanning_alert"
                | `Secret_scanning_alert_location -> `String "secret_scanning_alert_location"
                | `Security_and_analysis -> `String "security_and_analysis"
                | `Star -> `String "star"
                | `Status -> `String "status"
                | `Team -> `String "team"
                | `Team_add -> `String "team_add"
                | `Watch -> `String "watch"
                | `Workflow_dispatch -> `String "workflow_dispatch"
                | `Workflow_job -> `String "workflow_job"
                | `Workflow_run -> `String "workflow_run"

              type t =
                ([ `Branch_protection_rule
                 | `Check_run
                 | `Check_suite
                 | `Code_scanning_alert
                 | `Commit_comment
                 | `Content_reference
                 | `Create
                 | `Delete
                 | `Deploy_key
                 | `Deployment
                 | `Deployment_review
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
                 | `Merge_group
                 | `Merge_queue_entry
                 | `Milestone
                 | `Org_block
                 | `Organization
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
                 | `Secret_scanning_alert
                 | `Secret_scanning_alert_location
                 | `Security_and_analysis
                 | `Star
                 | `Status
                 | `Team
                 | `Team_add
                 | `Watch
                 | `Workflow_dispatch
                 | `Workflow_job
                 | `Workflow_run
                 ]
                [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Owner = struct
            module Primary = struct
              module Type = struct
                let t_of_yojson = function
                  | `String "Bot" -> Ok `Bot
                  | `String "Organization" -> Ok `Organization
                  | `String "User" -> Ok `User
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Bot -> `String "Bot"
                  | `Organization -> `String "Organization"
                  | `User -> `String "User"

                type t =
                  ([ `Bot
                   | `Organization
                   | `User
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                avatar_url : string option; [@default None]
                deleted : bool option; [@default None]
                email : string option; [@default None]
                events_url : string option; [@default None]
                followers_url : string option; [@default None]
                following_url : string option; [@default None]
                gists_url : string option; [@default None]
                gravatar_id : string option; [@default None]
                html_url : string option; [@default None]
                id : int;
                login : string;
                name : string option; [@default None]
                node_id : string option; [@default None]
                organizations_url : string option; [@default None]
                received_events_url : string option; [@default None]
                repos_url : string option; [@default None]
                site_admin : bool option; [@default None]
                starred_url : string option; [@default None]
                subscriptions_url : string option; [@default None]
                type_ : Type.t option; [@default None] [@key "type"]
                url : string option; [@default None]
                user_view_type : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Permissions = struct
            module Primary = struct
              module Actions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Checks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Content_references = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Contents = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Deployments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Discussions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Emails = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Environments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Issues = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Keys = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Members = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Metadata_ = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_plan = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_projects = struct
                let t_of_yojson = function
                  | `String "admin" -> Ok `Admin
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Admin -> `String "admin"
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Admin
                   | `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_self_hosted_runners = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_user_blocking = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Pages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Pull_requests = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Repository_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Repository_projects = struct
                let t_of_yojson = function
                  | `String "admin" -> Ok `Admin
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Admin -> `String "admin"
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Admin
                   | `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Secret_scanning_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Security_events = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Security_scanning_alert = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Single_file = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Statuses = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Team_discussions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Vulnerability_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Workflows = struct
                let t_of_yojson = function
                  | `String "read" -> Ok `Read
                  | `String "write" -> Ok `Write
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Read -> `String "read"
                  | `Write -> `String "write"

                type t =
                  ([ `Read
                   | `Write
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                actions : Actions.t option; [@default None]
                administration : Administration.t option; [@default None]
                checks : Checks.t option; [@default None]
                content_references : Content_references.t option; [@default None]
                contents : Contents.t option; [@default None]
                deployments : Deployments.t option; [@default None]
                discussions : Discussions.t option; [@default None]
                emails : Emails.t option; [@default None]
                environments : Environments.t option; [@default None]
                issues : Issues.t option; [@default None]
                keys : Keys.t option; [@default None]
                members : Members.t option; [@default None]
                metadata : Metadata_.t option; [@default None]
                organization_administration : Organization_administration.t option; [@default None]
                organization_hooks : Organization_hooks.t option; [@default None]
                organization_packages : Organization_packages.t option; [@default None]
                organization_plan : Organization_plan.t option; [@default None]
                organization_projects : Organization_projects.t option; [@default None]
                organization_secrets : Organization_secrets.t option; [@default None]
                organization_self_hosted_runners : Organization_self_hosted_runners.t option;
                    [@default None]
                organization_user_blocking : Organization_user_blocking.t option; [@default None]
                packages : Packages.t option; [@default None]
                pages : Pages.t option; [@default None]
                pull_requests : Pull_requests.t option; [@default None]
                repository_hooks : Repository_hooks.t option; [@default None]
                repository_projects : Repository_projects.t option; [@default None]
                secret_scanning_alerts : Secret_scanning_alerts.t option; [@default None]
                secrets : Secrets.t option; [@default None]
                security_events : Security_events.t option; [@default None]
                security_scanning_alert : Security_scanning_alert.t option; [@default None]
                single_file : Single_file.t option; [@default None]
                statuses : Statuses.t option; [@default None]
                team_discussions : Team_discussions.t option; [@default None]
                vulnerability_alerts : Vulnerability_alerts.t option; [@default None]
                workflows : Workflows.t option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            client_id : string option; [@default None]
            created_at : string option; [@default None]
            description : string option; [@default None]
            events : Events.t option; [@default None]
            external_url : string option; [@default None]
            html_url : string;
            id : int option; [@default None]
            name : string;
            node_id : string;
            owner : Owner.t option; [@default None]
            permissions : Permissions.t option; [@default None]
            slug : string option; [@default None]
            updated_at : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Conclusion = struct
        let t_of_yojson = function
          | `String "action_required" -> Ok `Action_required
          | `String "cancelled" -> Ok `Cancelled
          | `String "failure" -> Ok `Failure
          | `String "neutral" -> Ok `Neutral
          | `String "skipped" -> Ok `Skipped
          | `String "stale" -> Ok `Stale
          | `String "success" -> Ok `Success
          | `String "timed_out" -> Ok `Timed_out
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Action_required -> `String "action_required"
          | `Cancelled -> `String "cancelled"
          | `Failure -> `String "failure"
          | `Neutral -> `String "neutral"
          | `Skipped -> `String "skipped"
          | `Stale -> `String "stale"
          | `Success -> `String "success"
          | `Timed_out -> `String "timed_out"

        type t =
          ([ `Action_required
           | `Cancelled
           | `Failure
           | `Neutral
           | `Skipped
           | `Stale
           | `Success
           | `Timed_out
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Head_commit = struct
        module Primary = struct
          module Author = struct
            module Primary = struct
              type t = {
                date : string option; [@default None]
                email : string option; [@default None]
                name : string;
                username : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Committer = struct
            module Primary = struct
              type t = {
                date : string option; [@default None]
                email : string option; [@default None]
                name : string;
                username : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            author : Author.t;
            committer : Committer.t;
            id : string;
            message : string;
            timestamp : string;
            tree_id : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Pull_requests = struct
        module Items = struct
          module Primary = struct
            module Base = struct
              module Primary = struct
                module Repo = struct
                  module Primary = struct
                    type t = {
                      id : int;
                      name : string;
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = {
                  ref_ : string; [@key "ref"]
                  repo : Repo.t;
                  sha : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Head = struct
              module Primary = struct
                module Repo = struct
                  module Primary = struct
                    type t = {
                      id : int;
                      name : string;
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = {
                  ref_ : string; [@key "ref"]
                  repo : Repo.t;
                  sha : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              base : Base.t;
              head : Head.t;
              id : int;
              number : int;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Status_ = struct
        let t_of_yojson = function
          | `String "completed" -> Ok `Completed
          | `String "in_progress" -> Ok `In_progress
          | `String "queued" -> Ok `Queued
          | `String "requested" -> Ok `Requested
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Completed -> `String "completed"
          | `In_progress -> `String "in_progress"
          | `Queued -> `String "queued"
          | `Requested -> `String "requested"

        type t =
          ([ `Completed
           | `In_progress
           | `Queued
           | `Requested
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        after : string option; [@default None]
        app : App.t;
        before : string option; [@default None]
        check_runs_url : string;
        conclusion : Conclusion.t option; [@default None]
        created_at : string;
        head_branch : string option; [@default None]
        head_commit : Head_commit.t;
        head_sha : string;
        id : int;
        latest_check_runs_count : int;
        node_id : string;
        pull_requests : Pull_requests.t;
        rerequestable : bool option; [@default None]
        runs_rerequestable : bool option; [@default None]
        status : Status_.t option; [@default None]
        updated_at : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    check_suite : Check_suite_.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
