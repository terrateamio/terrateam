module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "closed" -> Ok "closed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Issue_ = struct
    module All_of = struct
      module Primary = struct
        module Active_lock_reason = struct
          let t_of_yojson = function
            | `String "resolved" -> Ok "resolved"
            | `String "off-topic" -> Ok "off-topic"
            | `String "too heated" -> Ok "too heated"
            | `String "spam" -> Ok "spam"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Assignee = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Assignees = struct
          module Items = struct
            module Primary = struct
              module Type = struct
                let t_of_yojson = function
                  | `String "Bot" -> Ok "Bot"
                  | `String "User" -> Ok "User"
                  | `String "Organization" -> Ok "Organization"
                  | `String "Mannequin" -> Ok "Mannequin"
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
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Author_association_ = struct
          let t_of_yojson = function
            | `String "COLLABORATOR" -> Ok "COLLABORATOR"
            | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
            | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
            | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
            | `String "MANNEQUIN" -> Ok "MANNEQUIN"
            | `String "MEMBER" -> Ok "MEMBER"
            | `String "NONE" -> Ok "NONE"
            | `String "OWNER" -> Ok "OWNER"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Labels = struct
          module Items = struct
            module Primary = struct
              type t = {
                color : string;
                default : bool;
                description : string option;
                id : int;
                name : string;
                node_id : string;
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Milestone_ = struct
          module Primary = struct
            module Creator = struct
              module Primary = struct
                module Type = struct
                  let t_of_yojson = function
                    | `String "Bot" -> Ok "Bot"
                    | `String "User" -> Ok "User"
                    | `String "Organization" -> Ok "Organization"
                    | `String "Mannequin" -> Ok "Mannequin"
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
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module State = struct
              let t_of_yojson = function
                | `String "open" -> Ok "open"
                | `String "closed" -> Ok "closed"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              closed_at : string option;
              closed_issues : int;
              created_at : string;
              creator : Creator.t option;
              description : string option;
              due_on : string option;
              html_url : string;
              id : int;
              labels_url : string;
              node_id : string;
              number : int;
              open_issues : int;
              state : State.t;
              title : string;
              updated_at : string;
              url : string;
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
                  | `String "security_and_analysis" -> Ok "security_and_analysis"
                  | `String "reminder" -> Ok "reminder"
                  | `String "pull_request_review_thread" -> Ok "pull_request_review_thread"
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
                  organization_administration : Organization_administration.t option;
                      [@default None]
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

        module Pull_request_ = struct
          module Primary = struct
            type t = {
              diff_url : string option; [@default None]
              html_url : string option; [@default None]
              merged_at : string option; [@default None]
              patch_url : string option; [@default None]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Reactions = struct
          module Primary = struct
            type t = {
              plus_one : int; [@key "+1"]
              minus_one : int; [@key "-1"]
              confused : int;
              eyes : int;
              heart : int;
              hooray : int;
              laugh : int;
              rocket : int;
              total_count : int;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module State = struct
          let t_of_yojson = function
            | `String "open" -> Ok "open"
            | `String "closed" -> Ok "closed"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module User = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          active_lock_reason : Active_lock_reason.t option;
          assignee : Assignee.t option; [@default None]
          assignees : Assignees.t;
          author_association : Author_association_.t;
          body : string option;
          closed_at : string option;
          comments : int;
          comments_url : string;
          created_at : string;
          draft : bool option; [@default None]
          events_url : string;
          html_url : string;
          id : int64;
          labels : Labels.t option; [@default None]
          labels_url : string;
          locked : bool option; [@default None]
          milestone : Milestone_.t option;
          node_id : string;
          number : int;
          performed_via_github_app : Performed_via_github_app.t option; [@default None]
          pull_request : Pull_request_.t option; [@default None]
          reactions : Reactions.t;
          repository_url : string;
          state : State.t;
          state_reason : string option; [@default None]
          timeline_url : string option; [@default None]
          title : string;
          updated_at : string;
          url : string;
          user : User.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Active_lock_reason = struct
          let t_of_yojson = function
            | `String "resolved" -> Ok "resolved"
            | `String "off-topic" -> Ok "off-topic"
            | `String "too heated" -> Ok "too heated"
            | `String "spam" -> Ok "spam"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Assignee = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Assignees = struct
          module Items = struct
            module Primary = struct
              module Type = struct
                let t_of_yojson = function
                  | `String "Bot" -> Ok "Bot"
                  | `String "User" -> Ok "User"
                  | `String "Organization" -> Ok "Organization"
                  | `String "Mannequin" -> Ok "Mannequin"
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
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Author_association_ = struct
          let t_of_yojson = function
            | `String "COLLABORATOR" -> Ok "COLLABORATOR"
            | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
            | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
            | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
            | `String "MANNEQUIN" -> Ok "MANNEQUIN"
            | `String "MEMBER" -> Ok "MEMBER"
            | `String "NONE" -> Ok "NONE"
            | `String "OWNER" -> Ok "OWNER"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Labels = struct
          module Items = struct
            module Primary = struct
              type t = {
                color : string;
                default : bool;
                description : string option;
                id : int;
                name : string;
                node_id : string;
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Milestone_ = struct
          module Primary = struct
            module Creator = struct
              module Primary = struct
                module Type = struct
                  let t_of_yojson = function
                    | `String "Bot" -> Ok "Bot"
                    | `String "User" -> Ok "User"
                    | `String "Organization" -> Ok "Organization"
                    | `String "Mannequin" -> Ok "Mannequin"
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
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module State = struct
              let t_of_yojson = function
                | `String "open" -> Ok "open"
                | `String "closed" -> Ok "closed"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              closed_at : string option;
              closed_issues : int;
              created_at : string;
              creator : Creator.t option;
              description : string option;
              due_on : string option;
              html_url : string;
              id : int;
              labels_url : string;
              node_id : string;
              number : int;
              open_issues : int;
              state : State.t;
              title : string;
              updated_at : string;
              url : string;
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
                  | `String "security_and_analysis" -> Ok "security_and_analysis"
                  | `String "reminder" -> Ok "reminder"
                  | `String "pull_request_review_thread" -> Ok "pull_request_review_thread"
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
                  organization_administration : Organization_administration.t option;
                      [@default None]
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

        module Pull_request_ = struct
          module Primary = struct
            type t = {
              diff_url : string option; [@default None]
              html_url : string option; [@default None]
              merged_at : string option; [@default None]
              patch_url : string option; [@default None]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Reactions = struct
          module Primary = struct
            type t = {
              plus_one : int; [@key "+1"]
              minus_one : int; [@key "-1"]
              confused : int;
              eyes : int;
              heart : int;
              hooray : int;
              laugh : int;
              rocket : int;
              total_count : int;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module State = struct
          let t_of_yojson = function
            | `String "open" -> Ok "open"
            | `String "closed" -> Ok "closed"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module User = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          active_lock_reason : Active_lock_reason.t option;
          assignee : Assignee.t option; [@default None]
          assignees : Assignees.t;
          author_association : Author_association_.t;
          body : string option;
          closed_at : string option;
          comments : int;
          comments_url : string;
          created_at : string;
          draft : bool option; [@default None]
          events_url : string;
          html_url : string;
          id : int64;
          labels : Labels.t option; [@default None]
          labels_url : string;
          locked : bool option; [@default None]
          milestone : Milestone_.t option;
          node_id : string;
          number : int;
          performed_via_github_app : Performed_via_github_app.t option; [@default None]
          pull_request : Pull_request_.t option; [@default None]
          reactions : Reactions.t;
          repository_url : string;
          state : State.t;
          state_reason : string option; [@default None]
          timeline_url : string option; [@default None]
          title : string;
          updated_at : string;
          url : string;
          user : User.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

    let of_yojson json =
      let open CCResult in
      flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    issue : Issue_.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
