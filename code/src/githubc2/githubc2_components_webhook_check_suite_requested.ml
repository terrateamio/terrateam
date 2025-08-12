module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "requested" -> Ok "requested"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Check_suite_ = struct
    module Primary = struct
      module App = struct
        module Primary = struct
          module Events = struct
            module Items = struct
              let t_of_yojson = function
                | `String "branch_protection_rule" -> Ok "branch_protection_rule"
                | `String "check_run" -> Ok "check_run"
                | `String "check_suite" -> Ok "check_suite"
                | `String "code_scanning_alert" -> Ok "code_scanning_alert"
                | `String "commit_comment" -> Ok "commit_comment"
                | `String "content_reference" -> Ok "content_reference"
                | `String "create" -> Ok "create"
                | `String "delete" -> Ok "delete"
                | `String "deployment" -> Ok "deployment"
                | `String "deployment_review" -> Ok "deployment_review"
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
                | `String "milestone" -> Ok "milestone"
                | `String "organization" -> Ok "organization"
                | `String "org_block" -> Ok "org_block"
                | `String "page_build" -> Ok "page_build"
                | `String "project" -> Ok "project"
                | `String "project_card" -> Ok "project_card"
                | `String "project_column" -> Ok "project_column"
                | `String "public" -> Ok "public"
                | `String "pull_request" -> Ok "pull_request"
                | `String "pull_request_review" -> Ok "pull_request_review"
                | `String "pull_request_review_comment" -> Ok "pull_request_review_comment"
                | `String "push" -> Ok "push"
                | `String "registry_package" -> Ok "registry_package"
                | `String "release" -> Ok "release"
                | `String "repository" -> Ok "repository"
                | `String "repository_dispatch" -> Ok "repository_dispatch"
                | `String "secret_scanning_alert" -> Ok "secret_scanning_alert"
                | `String "star" -> Ok "star"
                | `String "status" -> Ok "status"
                | `String "team" -> Ok "team"
                | `String "team_add" -> Ok "team_add"
                | `String "watch" -> Ok "watch"
                | `String "workflow_dispatch" -> Ok "workflow_dispatch"
                | `String "workflow_run" -> Ok "workflow_run"
                | `String "pull_request_review_thread" -> Ok "pull_request_review_thread"
                | `String "workflow_job" -> Ok "workflow_job"
                | `String "merge_queue_entry" -> Ok "merge_queue_entry"
                | `String "security_and_analysis" -> Ok "security_and_analysis"
                | `String "secret_scanning_alert_location" -> Ok "secret_scanning_alert_location"
                | `String "projects_v2_item" -> Ok "projects_v2_item"
                | `String "merge_group" -> Ok "merge_group"
                | `String "repository_import" -> Ok "repository_import"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Owner = struct
            module Primary = struct
              module Type = struct
                let t_of_yojson = function
                  | `String "Bot" -> Ok "Bot"
                  | `String "User" -> Ok "User"
                  | `String "Organization" -> Ok "Organization"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
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
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Checks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Content_references = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Contents = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Deployments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Discussions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Emails = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Environments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Issues = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Keys = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Members = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Metadata_ = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_plan = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_projects = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | `String "admin" -> Ok "admin"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_self_hosted_runners = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Organization_user_blocking = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Pages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Pull_requests = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Repository_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Repository_projects = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | `String "admin" -> Ok "admin"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Secret_scanning_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Security_events = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Security_scanning_alert = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Single_file = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Statuses = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Team_discussions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Vulnerability_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Workflows = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
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
            created_at : string option;
            description : string option;
            events : Events.t option; [@default None]
            external_url : string option;
            html_url : string;
            id : int option;
            name : string;
            node_id : string;
            owner : Owner.t option;
            permissions : Permissions.t option; [@default None]
            slug : string option; [@default None]
            updated_at : string option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Conclusion = struct
        let t_of_yojson = function
          | `String "success" -> Ok "success"
          | `String "failure" -> Ok "failure"
          | `String "neutral" -> Ok "neutral"
          | `String "cancelled" -> Ok "cancelled"
          | `String "timed_out" -> Ok "timed_out"
          | `String "action_required" -> Ok "action_required"
          | `String "stale" -> Ok "stale"
          | `String "skipped" -> Ok "skipped"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Head_commit = struct
        module Primary = struct
          module Author = struct
            module Primary = struct
              type t = {
                date : string option; [@default None]
                email : string option;
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
                email : string option;
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
          | `String "requested" -> Ok "requested"
          | `String "in_progress" -> Ok "in_progress"
          | `String "completed" -> Ok "completed"
          | `String "queued" -> Ok "queued"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        after : string option;
        app : App.t;
        before : string option;
        check_runs_url : string;
        conclusion : Conclusion.t option;
        created_at : string;
        head_branch : string option;
        head_commit : Head_commit.t;
        head_sha : string;
        id : int;
        latest_check_runs_count : int;
        node_id : string;
        pull_requests : Pull_requests.t;
        rerequestable : bool option; [@default None]
        runs_rerequestable : bool option; [@default None]
        status : Status_.t option;
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
