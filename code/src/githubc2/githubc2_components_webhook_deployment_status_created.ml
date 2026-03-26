module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "created" -> Ok `Created
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Created -> `String "created"

    type t = ([ `Created ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Check_run_ = struct
    module Primary = struct
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

      module Status_ = struct
        let t_of_yojson = function
          | `String "completed" -> Ok `Completed
          | `String "in_progress" -> Ok `In_progress
          | `String "pending" -> Ok `Pending
          | `String "queued" -> Ok `Queued
          | `String "waiting" -> Ok `Waiting
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Completed -> `String "completed"
          | `In_progress -> `String "in_progress"
          | `Pending -> `String "pending"
          | `Queued -> `String "queued"
          | `Waiting -> `String "waiting"

        type t =
          ([ `Completed
           | `In_progress
           | `Pending
           | `Queued
           | `Waiting
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        completed_at : string option; [@default None]
        conclusion : Conclusion.t option; [@default None]
        details_url : string;
        external_id : string;
        head_sha : string;
        html_url : string;
        id : int;
        name : string;
        node_id : string;
        started_at : string;
        status : Status_.t;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Deployment_ = struct
    module Primary = struct
      module Creator = struct
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

      module Payload = struct
        module V0 = struct
          type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      module Performed_via_github_app = struct
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
                | `String "secret_scanning_alert" -> Ok `Secret_scanning_alert
                | `String "secret_scanning_alert_location" -> Ok `Secret_scanning_alert_location
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
                | `Secret_scanning_alert -> `String "secret_scanning_alert"
                | `Secret_scanning_alert_location -> `String "secret_scanning_alert_location"
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
                 | `Secret_scanning_alert
                 | `Secret_scanning_alert_location
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

      type t = {
        created_at : string;
        creator : Creator.t option; [@default None]
        description : string option; [@default None]
        environment : string;
        id : int;
        node_id : string;
        original_environment : string;
        payload : Payload.t option; [@default None]
        performed_via_github_app : Performed_via_github_app.t option; [@default None]
        production_environment : bool option; [@default None]
        ref_ : string; [@key "ref"]
        repository_url : string;
        sha : string;
        statuses_url : string;
        task : string;
        transient_environment : bool option; [@default None]
        updated_at : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Deployment_status_ = struct
    module Primary = struct
      module Creator = struct
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

      module Performed_via_github_app = struct
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
                | `String "secret_scanning_alert" -> Ok `Secret_scanning_alert
                | `String "secret_scanning_alert_location" -> Ok `Secret_scanning_alert_location
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
                | `Secret_scanning_alert -> `String "secret_scanning_alert"
                | `Secret_scanning_alert_location -> `String "secret_scanning_alert_location"
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
                 | `Secret_scanning_alert
                 | `Secret_scanning_alert_location
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

      type t = {
        created_at : string;
        creator : Creator.t option; [@default None]
        deployment_url : string;
        description : string;
        environment : string;
        environment_url : string option; [@default None]
        id : int;
        log_url : string option; [@default None]
        node_id : string;
        performed_via_github_app : Performed_via_github_app.t option; [@default None]
        repository_url : string;
        state : string;
        target_url : string;
        updated_at : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Workflow_run_ = struct
    module Primary = struct
      module Actor_ = struct
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

      module Conclusion = struct
        let t_of_yojson = function
          | `String "action_required" -> Ok `Action_required
          | `String "cancelled" -> Ok `Cancelled
          | `String "failure" -> Ok `Failure
          | `String "neutral" -> Ok `Neutral
          | `String "stale" -> Ok `Stale
          | `String "startup_failure" -> Ok `Startup_failure
          | `String "success" -> Ok `Success
          | `String "timed_out" -> Ok `Timed_out
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Action_required -> `String "action_required"
          | `Cancelled -> `String "cancelled"
          | `Failure -> `String "failure"
          | `Neutral -> `String "neutral"
          | `Stale -> `String "stale"
          | `Startup_failure -> `String "startup_failure"
          | `Success -> `String "success"
          | `Timed_out -> `String "timed_out"

        type t =
          ([ `Action_required
           | `Cancelled
           | `Failure
           | `Neutral
           | `Stale
           | `Startup_failure
           | `Success
           | `Timed_out
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Head_commit = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Head_repository = struct
        module Primary = struct
          module Description = struct
            type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Owner = struct
            module Primary = struct
              type t = {
                avatar_url : string option; [@default None]
                events_url : string option; [@default None]
                followers_url : string option; [@default None]
                following_url : string option; [@default None]
                gists_url : string option; [@default None]
                gravatar_id : string option; [@default None]
                html_url : string option; [@default None]
                id : int option; [@default None]
                login : string option; [@default None]
                node_id : string option; [@default None]
                organizations_url : string option; [@default None]
                received_events_url : string option; [@default None]
                repos_url : string option; [@default None]
                site_admin : bool option; [@default None]
                starred_url : string option; [@default None]
                subscriptions_url : string option; [@default None]
                type_ : string option; [@default None] [@key "type"]
                url : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            archive_url : string option; [@default None]
            assignees_url : string option; [@default None]
            blobs_url : string option; [@default None]
            branches_url : string option; [@default None]
            collaborators_url : string option; [@default None]
            comments_url : string option; [@default None]
            commits_url : string option; [@default None]
            compare_url : string option; [@default None]
            contents_url : string option; [@default None]
            contributors_url : string option; [@default None]
            deployments_url : string option; [@default None]
            description : Description.t option; [@default None]
            downloads_url : string option; [@default None]
            events_url : string option; [@default None]
            fork : bool option; [@default None]
            forks_url : string option; [@default None]
            full_name : string option; [@default None]
            git_commits_url : string option; [@default None]
            git_refs_url : string option; [@default None]
            git_tags_url : string option; [@default None]
            hooks_url : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            issue_comment_url : string option; [@default None]
            issue_events_url : string option; [@default None]
            issues_url : string option; [@default None]
            keys_url : string option; [@default None]
            labels_url : string option; [@default None]
            languages_url : string option; [@default None]
            merges_url : string option; [@default None]
            milestones_url : string option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            notifications_url : string option; [@default None]
            owner : Owner.t option; [@default None]
            private_ : bool option; [@default None] [@key "private"]
            pulls_url : string option; [@default None]
            releases_url : string option; [@default None]
            stargazers_url : string option; [@default None]
            statuses_url : string option; [@default None]
            subscribers_url : string option; [@default None]
            subscription_url : string option; [@default None]
            tags_url : string option; [@default None]
            teams_url : string option; [@default None]
            trees_url : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Previous_attempt_url = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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

      module Referenced_workflows = struct
        module Items = struct
          module Primary = struct
            type t = {
              path : string;
              ref_ : string option; [@default None] [@key "ref"]
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Repository_ = struct
        module Primary = struct
          module Description = struct
            type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Owner = struct
            module Primary = struct
              type t = {
                avatar_url : string option; [@default None]
                events_url : string option; [@default None]
                followers_url : string option; [@default None]
                following_url : string option; [@default None]
                gists_url : string option; [@default None]
                gravatar_id : string option; [@default None]
                html_url : string option; [@default None]
                id : int option; [@default None]
                login : string option; [@default None]
                node_id : string option; [@default None]
                organizations_url : string option; [@default None]
                received_events_url : string option; [@default None]
                repos_url : string option; [@default None]
                site_admin : bool option; [@default None]
                starred_url : string option; [@default None]
                subscriptions_url : string option; [@default None]
                type_ : string option; [@default None] [@key "type"]
                url : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            archive_url : string option; [@default None]
            assignees_url : string option; [@default None]
            blobs_url : string option; [@default None]
            branches_url : string option; [@default None]
            collaborators_url : string option; [@default None]
            comments_url : string option; [@default None]
            commits_url : string option; [@default None]
            compare_url : string option; [@default None]
            contents_url : string option; [@default None]
            contributors_url : string option; [@default None]
            deployments_url : string option; [@default None]
            description : Description.t option; [@default None]
            downloads_url : string option; [@default None]
            events_url : string option; [@default None]
            fork : bool option; [@default None]
            forks_url : string option; [@default None]
            full_name : string option; [@default None]
            git_commits_url : string option; [@default None]
            git_refs_url : string option; [@default None]
            git_tags_url : string option; [@default None]
            hooks_url : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            issue_comment_url : string option; [@default None]
            issue_events_url : string option; [@default None]
            issues_url : string option; [@default None]
            keys_url : string option; [@default None]
            labels_url : string option; [@default None]
            languages_url : string option; [@default None]
            merges_url : string option; [@default None]
            milestones_url : string option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            notifications_url : string option; [@default None]
            owner : Owner.t option; [@default None]
            private_ : bool option; [@default None] [@key "private"]
            pulls_url : string option; [@default None]
            releases_url : string option; [@default None]
            stargazers_url : string option; [@default None]
            statuses_url : string option; [@default None]
            subscribers_url : string option; [@default None]
            subscription_url : string option; [@default None]
            tags_url : string option; [@default None]
            teams_url : string option; [@default None]
            trees_url : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Status_ = struct
        let t_of_yojson = function
          | `String "completed" -> Ok `Completed
          | `String "in_progress" -> Ok `In_progress
          | `String "pending" -> Ok `Pending
          | `String "queued" -> Ok `Queued
          | `String "requested" -> Ok `Requested
          | `String "waiting" -> Ok `Waiting
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Completed -> `String "completed"
          | `In_progress -> `String "in_progress"
          | `Pending -> `String "pending"
          | `Queued -> `String "queued"
          | `Requested -> `String "requested"
          | `Waiting -> `String "waiting"

        type t =
          ([ `Completed
           | `In_progress
           | `Pending
           | `Queued
           | `Requested
           | `Waiting
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Triggering_actor = struct
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

      type t = {
        actor : Actor_.t option; [@default None]
        artifacts_url : string option; [@default None]
        cancel_url : string option; [@default None]
        check_suite_id : int;
        check_suite_node_id : string;
        check_suite_url : string option; [@default None]
        conclusion : Conclusion.t option; [@default None]
        created_at : string;
        display_title : string;
        event : string;
        head_branch : string;
        head_commit : Head_commit.t option; [@default None]
        head_repository : Head_repository.t option; [@default None]
        head_sha : string;
        html_url : string;
        id : int;
        jobs_url : string option; [@default None]
        logs_url : string option; [@default None]
        name : string;
        node_id : string;
        path : string;
        previous_attempt_url : Previous_attempt_url.t option; [@default None]
        pull_requests : Pull_requests.t;
        referenced_workflows : Referenced_workflows.t option; [@default None]
        repository : Repository_.t option; [@default None]
        rerun_url : string option; [@default None]
        run_attempt : int;
        run_number : int;
        run_started_at : string;
        status : Status_.t;
        triggering_actor : Triggering_actor.t option; [@default None]
        updated_at : string;
        url : string;
        workflow_id : int;
        workflow_url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    check_run : Check_run_.t option; [@default None]
    deployment : Deployment_.t;
    deployment_status : Deployment_status_.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
    workflow : Githubc2_components_webhooks_workflow.t option; [@default None]
    workflow_run : Workflow_run_.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
