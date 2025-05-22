module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "approved" -> Ok "approved"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Workflow_job_runs = struct
    module Items = struct
      module Primary = struct
        module Conclusion = struct
          type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          conclusion : Conclusion.t option; [@default None]
          created_at : string option; [@default None]
          environment : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          name : string option; [@default None]
          status : string option; [@default None]
          updated_at : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
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
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      module Head_repository = struct
        module Primary = struct
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
                user_view_type : string option; [@default None]
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
            description : string option; [@default None]
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
                user_view_type : string option; [@default None]
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
            description : string option; [@default None]
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
        actor : Actor_.t option;
        artifacts_url : string option; [@default None]
        cancel_url : string option; [@default None]
        check_suite_id : int;
        check_suite_node_id : string;
        check_suite_url : string option; [@default None]
        conclusion : Conclusion.t option;
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
        previous_attempt_url : string option; [@default None]
        pull_requests : Pull_requests.t;
        referenced_workflows : Referenced_workflows.t option; [@default None]
        repository : Repository_.t option; [@default None]
        rerun_url : string option; [@default None]
        run_attempt : int;
        run_number : int;
        run_started_at : string;
        status : Status_.t;
        triggering_actor : Triggering_actor.t option;
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
    approver : Githubc2_components_webhooks_approver.t option; [@default None]
    comment : string option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t;
    repository : Githubc2_components_repository_webhooks.t;
    reviewers : Githubc2_components_webhooks_reviewers.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
    since : string;
    workflow_job_run : Githubc2_components_webhooks_workflow_job_run.t option; [@default None]
    workflow_job_runs : Workflow_job_runs.t option; [@default None]
    workflow_run : Workflow_run_.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
