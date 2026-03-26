module Primary = struct
  module Active_lock_reason = struct
    let t_of_yojson = function
      | `String "off-topic" -> Ok `Off_topic
      | `String "resolved" -> Ok `Resolved
      | `String "spam" -> Ok `Spam
      | `String "too heated" -> Ok `Too_heated
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Off_topic -> `String "off-topic"
      | `Resolved -> `String "resolved"
      | `Spam -> `String "spam"
      | `Too_heated -> `String "too heated"

    type t =
      ([ `Off_topic
       | `Resolved
       | `Spam
       | `Too_heated
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Assignee = struct
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

  module Assignees = struct
    module Items = struct
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

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Author_association_ = struct
    let t_of_yojson = function
      | `String "COLLABORATOR" -> Ok `COLLABORATOR
      | `String "CONTRIBUTOR" -> Ok `CONTRIBUTOR
      | `String "FIRST_TIMER" -> Ok `FIRST_TIMER
      | `String "FIRST_TIME_CONTRIBUTOR" -> Ok `FIRST_TIME_CONTRIBUTOR
      | `String "MANNEQUIN" -> Ok `MANNEQUIN
      | `String "MEMBER" -> Ok `MEMBER
      | `String "NONE" -> Ok `NONE
      | `String "OWNER" -> Ok `OWNER
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `COLLABORATOR -> `String "COLLABORATOR"
      | `CONTRIBUTOR -> `String "CONTRIBUTOR"
      | `FIRST_TIMER -> `String "FIRST_TIMER"
      | `FIRST_TIME_CONTRIBUTOR -> `String "FIRST_TIME_CONTRIBUTOR"
      | `MANNEQUIN -> `String "MANNEQUIN"
      | `MEMBER -> `String "MEMBER"
      | `NONE -> `String "NONE"
      | `OWNER -> `String "OWNER"

    type t =
      ([ `COLLABORATOR
       | `CONTRIBUTOR
       | `FIRST_TIMER
       | `FIRST_TIME_CONTRIBUTOR
       | `MANNEQUIN
       | `MEMBER
       | `NONE
       | `OWNER
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Labels = struct
    module Items = struct
      module Primary = struct
        type t = {
          color : string;
          default : bool;
          description : string option; [@default None]
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

      module State = struct
        let t_of_yojson = function
          | `String "closed" -> Ok `Closed
          | `String "open" -> Ok `Open
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Closed -> `String "closed"
          | `Open -> `String "open"

        type t =
          ([ `Closed
           | `Open
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        closed_at : string option; [@default None]
        closed_issues : int;
        created_at : string;
        creator : Creator.t option; [@default None]
        description : string option; [@default None]
        due_on : string option; [@default None]
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
            | `String "push" -> Ok `Push
            | `String "registry_package" -> Ok `Registry_package
            | `String "release" -> Ok `Release
            | `String "repository" -> Ok `Repository
            | `String "repository_dispatch" -> Ok `Repository_dispatch
            | `String "secret_scanning_alert" -> Ok `Secret_scanning_alert
            | `String "star" -> Ok `Star
            | `String "status" -> Ok `Status
            | `String "team" -> Ok `Team
            | `String "team_add" -> Ok `Team_add
            | `String "watch" -> Ok `Watch
            | `String "workflow_dispatch" -> Ok `Workflow_dispatch
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
            | `Push -> `String "push"
            | `Registry_package -> `String "registry_package"
            | `Release -> `String "release"
            | `Repository -> `String "repository"
            | `Repository_dispatch -> `String "repository_dispatch"
            | `Secret_scanning_alert -> `String "secret_scanning_alert"
            | `Star -> `String "star"
            | `Status -> `String "status"
            | `Team -> `String "team"
            | `Team_add -> `String "team_add"
            | `Watch -> `String "watch"
            | `Workflow_dispatch -> `String "workflow_dispatch"
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
             | `Push
             | `Registry_package
             | `Release
             | `Repository
             | `Repository_dispatch
             | `Secret_scanning_alert
             | `Star
             | `Status
             | `Team
             | `Team_add
             | `Watch
             | `Workflow_dispatch
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
      | `String "closed" -> Ok `Closed
      | `String "open" -> Ok `Open
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Closed -> `String "closed"
      | `Open -> `String "open"

    type t =
      ([ `Closed
       | `Open
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Sub_issues_summary_ = struct
    module Primary = struct
      type t = {
        completed : int;
        percent_completed : int;
        total : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module User = struct
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
        id : int64;
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
    active_lock_reason : Active_lock_reason.t option; [@default None]
    assignee : Assignee.t option; [@default None]
    assignees : Assignees.t;
    author_association : Author_association_.t;
    body : string option; [@default None]
    closed_at : string option; [@default None]
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
    milestone : Milestone_.t option; [@default None]
    node_id : string;
    number : int;
    performed_via_github_app : Performed_via_github_app.t option; [@default None]
    pull_request : Pull_request_.t option; [@default None]
    reactions : Reactions.t;
    repository_url : string;
    state : State.t option; [@default None]
    state_reason : string option; [@default None]
    sub_issues_summary : Sub_issues_summary_.t option; [@default None]
    timeline_url : string option; [@default None]
    title : string;
    type_ : Githubc2_components_issue_type.t option; [@default None] [@key "type"]
    updated_at : string;
    url : string;
    user : User.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
