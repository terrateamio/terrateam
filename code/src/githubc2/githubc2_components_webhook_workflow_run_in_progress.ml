module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "in_progress" -> Ok "in_progress"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Workflow_ = struct
    module Primary = struct
      type t = {
        badge_url : string;
        created_at : string;
        html_url : string;
        id : int;
        name : string;
        node_id : string;
        path : string;
        state : string;
        updated_at : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Workflow_run_ = struct
    module All_of = struct
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

        module Head_repository = struct
          module Primary = struct
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

            type t = {
              archive_url : string;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              deployments_url : string;
              description : string option;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              hooks_url : string;
              html_url : string;
              id : int;
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              languages_url : string;
              merges_url : string;
              milestones_url : string;
              name : string option;
              node_id : string;
              notifications_url : string;
              owner : Owner.t option;
              private_ : bool; [@key "private"]
              pulls_url : string;
              releases_url : string;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              tags_url : string;
              teams_url : string;
              trees_url : string;
              url : string;
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
                id : float;
                number : float;
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

            type t = {
              archive_url : string;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              deployments_url : string;
              description : string option;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              hooks_url : string;
              html_url : string;
              id : int;
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              languages_url : string;
              merges_url : string;
              milestones_url : string;
              name : string;
              node_id : string;
              notifications_url : string;
              owner : Owner.t option;
              private_ : bool; [@key "private"]
              pulls_url : string;
              releases_url : string;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              tags_url : string;
              teams_url : string;
              trees_url : string;
              url : string;
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          actor : Actor_.t option;
          artifacts_url : string;
          cancel_url : string;
          check_suite_id : int;
          check_suite_node_id : string;
          check_suite_url : string;
          conclusion : Conclusion.t option;
          created_at : string;
          event : string;
          head_branch : string option;
          head_commit : Head_commit.t;
          head_repository : Head_repository.t;
          head_sha : string;
          html_url : string;
          id : int;
          jobs_url : string;
          logs_url : string;
          name : string option;
          node_id : string;
          path : string;
          previous_attempt_url : string option;
          pull_requests : Pull_requests.t;
          referenced_workflows : Referenced_workflows.t option; [@default None]
          repository : Repository_.t;
          rerun_url : string;
          run_attempt : int;
          run_number : int;
          run_started_at : string;
          status : Status_.t;
          triggering_actor : Triggering_actor.t option;
          updated_at : string;
          url : string;
          workflow_id : int;
          workflow_url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
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

        module Head_repository = struct
          module Primary = struct
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

            type t = {
              archive_url : string;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              deployments_url : string;
              description : string option;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              hooks_url : string;
              html_url : string;
              id : int;
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              languages_url : string;
              merges_url : string;
              milestones_url : string;
              name : string option;
              node_id : string;
              notifications_url : string;
              owner : Owner.t option;
              private_ : bool; [@key "private"]
              pulls_url : string;
              releases_url : string;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              tags_url : string;
              teams_url : string;
              trees_url : string;
              url : string;
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
                id : float;
                number : float;
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

            type t = {
              archive_url : string;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              deployments_url : string;
              description : string option;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              hooks_url : string;
              html_url : string;
              id : int;
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              languages_url : string;
              merges_url : string;
              milestones_url : string;
              name : string;
              node_id : string;
              notifications_url : string;
              owner : Owner.t option;
              private_ : bool; [@key "private"]
              pulls_url : string;
              releases_url : string;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              tags_url : string;
              teams_url : string;
              trees_url : string;
              url : string;
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
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          actor : Actor_.t option;
          artifacts_url : string;
          cancel_url : string;
          check_suite_id : int;
          check_suite_node_id : string;
          check_suite_url : string;
          conclusion : Conclusion.t option;
          created_at : string;
          event : string;
          head_branch : string option;
          head_commit : Head_commit.t;
          head_repository : Head_repository.t;
          head_sha : string;
          html_url : string;
          id : int;
          jobs_url : string;
          logs_url : string;
          name : string option;
          node_id : string;
          path : string;
          previous_attempt_url : string option;
          pull_requests : Pull_requests.t;
          referenced_workflows : Referenced_workflows.t option; [@default None]
          repository : Repository_.t;
          rerun_url : string;
          run_attempt : int;
          run_number : int;
          run_started_at : string;
          status : Status_.t;
          triggering_actor : Triggering_actor.t option;
          updated_at : string;
          url : string;
          workflow_id : int;
          workflow_url : string;
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
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
    workflow : Workflow_.t option;
    workflow_run : Workflow_run_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
