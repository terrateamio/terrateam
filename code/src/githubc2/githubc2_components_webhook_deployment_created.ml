module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "created" -> Ok "created"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Deployment_ = struct
    module Primary = struct
      module Creator = struct
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

      module Payload = struct
        module V0 = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        module V1 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
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
                | `String "workflow_job" -> Ok "workflow_job"
                | `String "pull_request_review_thread" -> Ok "pull_request_review_thread"
                | `String "merge_queue_entry" -> Ok "merge_queue_entry"
                | `String "secret_scanning_alert_location" -> Ok "secret_scanning_alert_location"
                | `String "merge_group" -> Ok "merge_group"
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
        payload : Payload.t;
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

  module Workflow_run_ = struct
    module Primary = struct
      module Actor_ = struct
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

      module Conclusion = struct
        let t_of_yojson = function
          | `String "success" -> Ok "success"
          | `String "failure" -> Ok "failure"
          | `String "neutral" -> Ok "neutral"
          | `String "cancelled" -> Ok "cancelled"
          | `String "timed_out" -> Ok "timed_out"
          | `String "action_required" -> Ok "action_required"
          | `String "stale" -> Ok "stale"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
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
          | `String "requested" -> Ok "requested"
          | `String "in_progress" -> Ok "in_progress"
          | `String "completed" -> Ok "completed"
          | `String "queued" -> Ok "queued"
          | `String "waiting" -> Ok "waiting"
          | `String "pending" -> Ok "pending"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Triggering_actor = struct
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
    deployment : Deployment_.t;
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
