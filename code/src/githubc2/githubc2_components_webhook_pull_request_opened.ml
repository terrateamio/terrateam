module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "opened" -> Ok "opened"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_request_ = struct
    module All_of = struct
      module Primary = struct
        module Links_ = struct
          module Primary = struct
            type t = {
              comments : Githubc2_components_link.t;
              commits : Githubc2_components_link.t;
              html : Githubc2_components_link.t;
              issue : Githubc2_components_link.t;
              review_comment : Githubc2_components_link.t;
              review_comments : Githubc2_components_link.t;
              self : Githubc2_components_link.t;
              statuses : Githubc2_components_link.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Assignees = struct
          type t = Githubc2_components_simple_user.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Base = struct
          module Primary = struct
            module Repo = struct
              module Primary = struct
                module Owner = struct
                  module Primary = struct
                    type t = {
                      avatar_url : string;
                      events_url : string;
                      followers_url : string;
                      following_url : string;
                      gists_url : string;
                      gravatar_id : string option;
                      html_url : string;
                      id : int;
                      login : string;
                      node_id : string;
                      organizations_url : string;
                      received_events_url : string;
                      repos_url : string;
                      site_admin : bool;
                      starred_url : string;
                      subscriptions_url : string;
                      type_ : string; [@key "type"]
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Permissions = struct
                  module Primary = struct
                    type t = {
                      admin : bool;
                      maintain : bool option; [@default None]
                      pull : bool;
                      push : bool;
                      triage : bool option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Topics = struct
                  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = {
                  allow_forking : bool option; [@default None]
                  allow_merge_commit : bool option; [@default None]
                  allow_rebase_merge : bool option; [@default None]
                  allow_squash_merge : bool option; [@default None]
                  archive_url : string;
                  archived : bool;
                  assignees_url : string;
                  blobs_url : string;
                  branches_url : string;
                  clone_url : string;
                  collaborators_url : string;
                  comments_url : string;
                  commits_url : string;
                  compare_url : string;
                  contents_url : string;
                  contributors_url : string;
                  created_at : string;
                  default_branch : string;
                  deployments_url : string;
                  description : string option;
                  disabled : bool;
                  downloads_url : string;
                  events_url : string;
                  fork : bool;
                  forks : int;
                  forks_count : int;
                  forks_url : string;
                  full_name : string;
                  git_commits_url : string;
                  git_refs_url : string;
                  git_tags_url : string;
                  git_url : string;
                  has_discussions : bool;
                  has_downloads : bool;
                  has_issues : bool;
                  has_pages : bool;
                  has_projects : bool;
                  has_wiki : bool;
                  homepage : string option;
                  hooks_url : string;
                  html_url : string;
                  id : int;
                  is_template : bool option; [@default None]
                  issue_comment_url : string;
                  issue_events_url : string;
                  issues_url : string;
                  keys_url : string;
                  labels_url : string;
                  language : string option;
                  languages_url : string;
                  license : Githubc2_components_nullable_license_simple.t option;
                  master_branch : string option; [@default None]
                  merges_url : string;
                  milestones_url : string;
                  mirror_url : string option;
                  name : string;
                  node_id : string;
                  notifications_url : string;
                  open_issues : int;
                  open_issues_count : int;
                  owner : Owner.t;
                  permissions : Permissions.t option; [@default None]
                  private_ : bool; [@key "private"]
                  pulls_url : string;
                  pushed_at : string;
                  releases_url : string;
                  size : int;
                  ssh_url : string;
                  stargazers_count : int;
                  stargazers_url : string;
                  statuses_url : string;
                  subscribers_url : string;
                  subscription_url : string;
                  svn_url : string;
                  tags_url : string;
                  teams_url : string;
                  temp_clone_token : string option; [@default None]
                  topics : Topics.t option; [@default None]
                  trees_url : string;
                  updated_at : string;
                  url : string;
                  visibility : string option; [@default None]
                  watchers : int;
                  watchers_count : int;
                  web_commit_signoff_required : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module User = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              label : string;
              ref_ : string; [@key "ref"]
              repo : Repo.t;
              sha : string;
              user : User.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Head = struct
          module Primary = struct
            module Repo = struct
              module Primary = struct
                module License_ = struct
                  module Primary = struct
                    type t = {
                      key : string;
                      name : string;
                      node_id : string;
                      spdx_id : string option;
                      url : string option;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Owner = struct
                  module Primary = struct
                    type t = {
                      avatar_url : string;
                      events_url : string;
                      followers_url : string;
                      following_url : string;
                      gists_url : string;
                      gravatar_id : string option;
                      html_url : string;
                      id : int;
                      login : string;
                      node_id : string;
                      organizations_url : string;
                      received_events_url : string;
                      repos_url : string;
                      site_admin : bool;
                      starred_url : string;
                      subscriptions_url : string;
                      type_ : string; [@key "type"]
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Permissions = struct
                  module Primary = struct
                    type t = {
                      admin : bool;
                      maintain : bool option; [@default None]
                      pull : bool;
                      push : bool;
                      triage : bool option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Topics = struct
                  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = {
                  allow_forking : bool option; [@default None]
                  allow_merge_commit : bool option; [@default None]
                  allow_rebase_merge : bool option; [@default None]
                  allow_squash_merge : bool option; [@default None]
                  archive_url : string;
                  archived : bool;
                  assignees_url : string;
                  blobs_url : string;
                  branches_url : string;
                  clone_url : string;
                  collaborators_url : string;
                  comments_url : string;
                  commits_url : string;
                  compare_url : string;
                  contents_url : string;
                  contributors_url : string;
                  created_at : string;
                  default_branch : string;
                  deployments_url : string;
                  description : string option;
                  disabled : bool;
                  downloads_url : string;
                  events_url : string;
                  fork : bool;
                  forks : int;
                  forks_count : int;
                  forks_url : string;
                  full_name : string;
                  git_commits_url : string;
                  git_refs_url : string;
                  git_tags_url : string;
                  git_url : string;
                  has_discussions : bool;
                  has_downloads : bool;
                  has_issues : bool;
                  has_pages : bool;
                  has_projects : bool;
                  has_wiki : bool;
                  homepage : string option;
                  hooks_url : string;
                  html_url : string;
                  id : int;
                  is_template : bool option; [@default None]
                  issue_comment_url : string;
                  issue_events_url : string;
                  issues_url : string;
                  keys_url : string;
                  labels_url : string;
                  language : string option;
                  languages_url : string;
                  license : License_.t option;
                  master_branch : string option; [@default None]
                  merges_url : string;
                  milestones_url : string;
                  mirror_url : string option;
                  name : string;
                  node_id : string;
                  notifications_url : string;
                  open_issues : int;
                  open_issues_count : int;
                  owner : Owner.t;
                  permissions : Permissions.t option; [@default None]
                  private_ : bool; [@key "private"]
                  pulls_url : string;
                  pushed_at : string;
                  releases_url : string;
                  size : int;
                  ssh_url : string;
                  stargazers_count : int;
                  stargazers_url : string;
                  statuses_url : string;
                  subscribers_url : string;
                  subscription_url : string;
                  svn_url : string;
                  tags_url : string;
                  teams_url : string;
                  temp_clone_token : string option; [@default None]
                  topics : Topics.t option; [@default None]
                  trees_url : string;
                  updated_at : string;
                  url : string;
                  visibility : string option; [@default None]
                  watchers : int;
                  watchers_count : int;
                  web_commit_signoff_required : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module User = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              label : string;
              ref_ : string; [@key "ref"]
              repo : Repo.t option;
              sha : string;
              user : User.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Labels = struct
          module Items = struct
            module Primary = struct
              type t = {
                color : string;
                default : bool;
                description : string option;
                id : int64;
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

        module Merge_commit_message = struct
          let t_of_yojson = function
            | `String "PR_BODY" -> Ok "PR_BODY"
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "BLANK" -> Ok "BLANK"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Merge_commit_title = struct
          let t_of_yojson = function
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "MERGE_MESSAGE" -> Ok "MERGE_MESSAGE"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Requested_reviewers = struct
          type t = Githubc2_components_simple_user.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Requested_teams = struct
          type t = Githubc2_components_team_simple.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Squash_merge_commit_message = struct
          let t_of_yojson = function
            | `String "PR_BODY" -> Ok "PR_BODY"
            | `String "COMMIT_MESSAGES" -> Ok "COMMIT_MESSAGES"
            | `String "BLANK" -> Ok "BLANK"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Squash_merge_commit_title = struct
          let t_of_yojson = function
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "COMMIT_OR_PR_TITLE" -> Ok "COMMIT_OR_PR_TITLE"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
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
          links_ : Links_.t; [@key "_links"]
          active_lock_reason : string option; [@default None]
          additions : int;
          allow_auto_merge : bool; [@default false]
          allow_update_branch : bool option; [@default None]
          assignee : Githubc2_components_nullable_simple_user.t option;
          assignees : Assignees.t option; [@default None]
          author_association : Githubc2_components_author_association.t;
          auto_merge : Githubc2_components_auto_merge.t option;
          base : Base.t;
          body : string option;
          changed_files : int;
          closed_at : string option;
          comments : int;
          comments_url : string;
          commits : int;
          commits_url : string;
          created_at : string;
          delete_branch_on_merge : bool; [@default false]
          deletions : int;
          diff_url : string;
          draft : bool option; [@default None]
          head : Head.t;
          html_url : string;
          id : int;
          issue_url : string;
          labels : Labels.t;
          locked : bool;
          maintainer_can_modify : bool;
          merge_commit_message : Merge_commit_message.t option; [@default None]
          merge_commit_sha : string option;
          merge_commit_title : Merge_commit_title.t option; [@default None]
          mergeable : bool option;
          mergeable_state : string;
          merged : bool;
          merged_at : string option;
          merged_by : Githubc2_components_nullable_simple_user.t option;
          milestone : Githubc2_components_nullable_milestone.t option;
          node_id : string;
          number : int;
          patch_url : string;
          rebaseable : bool option; [@default None]
          requested_reviewers : Requested_reviewers.t option; [@default None]
          requested_teams : Requested_teams.t option; [@default None]
          review_comment_url : string;
          review_comments : int;
          review_comments_url : string;
          squash_merge_commit_message : Squash_merge_commit_message.t option; [@default None]
          squash_merge_commit_title : Squash_merge_commit_title.t option; [@default None]
          state : State.t;
          statuses_url : string;
          title : string;
          updated_at : string;
          url : string;
          use_squash_pr_title_as_default : bool; [@default false]
          user : Githubc2_components_simple_user.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Links_ = struct
          module Primary = struct
            type t = {
              comments : Githubc2_components_link.t;
              commits : Githubc2_components_link.t;
              html : Githubc2_components_link.t;
              issue : Githubc2_components_link.t;
              review_comment : Githubc2_components_link.t;
              review_comments : Githubc2_components_link.t;
              self : Githubc2_components_link.t;
              statuses : Githubc2_components_link.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Assignees = struct
          type t = Githubc2_components_simple_user.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Base = struct
          module Primary = struct
            module Repo = struct
              module Primary = struct
                module Owner = struct
                  module Primary = struct
                    type t = {
                      avatar_url : string;
                      events_url : string;
                      followers_url : string;
                      following_url : string;
                      gists_url : string;
                      gravatar_id : string option;
                      html_url : string;
                      id : int;
                      login : string;
                      node_id : string;
                      organizations_url : string;
                      received_events_url : string;
                      repos_url : string;
                      site_admin : bool;
                      starred_url : string;
                      subscriptions_url : string;
                      type_ : string; [@key "type"]
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Permissions = struct
                  module Primary = struct
                    type t = {
                      admin : bool;
                      maintain : bool option; [@default None]
                      pull : bool;
                      push : bool;
                      triage : bool option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Topics = struct
                  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = {
                  allow_forking : bool option; [@default None]
                  allow_merge_commit : bool option; [@default None]
                  allow_rebase_merge : bool option; [@default None]
                  allow_squash_merge : bool option; [@default None]
                  archive_url : string;
                  archived : bool;
                  assignees_url : string;
                  blobs_url : string;
                  branches_url : string;
                  clone_url : string;
                  collaborators_url : string;
                  comments_url : string;
                  commits_url : string;
                  compare_url : string;
                  contents_url : string;
                  contributors_url : string;
                  created_at : string;
                  default_branch : string;
                  deployments_url : string;
                  description : string option;
                  disabled : bool;
                  downloads_url : string;
                  events_url : string;
                  fork : bool;
                  forks : int;
                  forks_count : int;
                  forks_url : string;
                  full_name : string;
                  git_commits_url : string;
                  git_refs_url : string;
                  git_tags_url : string;
                  git_url : string;
                  has_discussions : bool;
                  has_downloads : bool;
                  has_issues : bool;
                  has_pages : bool;
                  has_projects : bool;
                  has_wiki : bool;
                  homepage : string option;
                  hooks_url : string;
                  html_url : string;
                  id : int;
                  is_template : bool option; [@default None]
                  issue_comment_url : string;
                  issue_events_url : string;
                  issues_url : string;
                  keys_url : string;
                  labels_url : string;
                  language : string option;
                  languages_url : string;
                  license : Githubc2_components_nullable_license_simple.t option;
                  master_branch : string option; [@default None]
                  merges_url : string;
                  milestones_url : string;
                  mirror_url : string option;
                  name : string;
                  node_id : string;
                  notifications_url : string;
                  open_issues : int;
                  open_issues_count : int;
                  owner : Owner.t;
                  permissions : Permissions.t option; [@default None]
                  private_ : bool; [@key "private"]
                  pulls_url : string;
                  pushed_at : string;
                  releases_url : string;
                  size : int;
                  ssh_url : string;
                  stargazers_count : int;
                  stargazers_url : string;
                  statuses_url : string;
                  subscribers_url : string;
                  subscription_url : string;
                  svn_url : string;
                  tags_url : string;
                  teams_url : string;
                  temp_clone_token : string option; [@default None]
                  topics : Topics.t option; [@default None]
                  trees_url : string;
                  updated_at : string;
                  url : string;
                  visibility : string option; [@default None]
                  watchers : int;
                  watchers_count : int;
                  web_commit_signoff_required : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module User = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              label : string;
              ref_ : string; [@key "ref"]
              repo : Repo.t;
              sha : string;
              user : User.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Head = struct
          module Primary = struct
            module Repo = struct
              module Primary = struct
                module License_ = struct
                  module Primary = struct
                    type t = {
                      key : string;
                      name : string;
                      node_id : string;
                      spdx_id : string option;
                      url : string option;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Owner = struct
                  module Primary = struct
                    type t = {
                      avatar_url : string;
                      events_url : string;
                      followers_url : string;
                      following_url : string;
                      gists_url : string;
                      gravatar_id : string option;
                      html_url : string;
                      id : int;
                      login : string;
                      node_id : string;
                      organizations_url : string;
                      received_events_url : string;
                      repos_url : string;
                      site_admin : bool;
                      starred_url : string;
                      subscriptions_url : string;
                      type_ : string; [@key "type"]
                      url : string;
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Permissions = struct
                  module Primary = struct
                    type t = {
                      admin : bool;
                      maintain : bool option; [@default None]
                      pull : bool;
                      push : bool;
                      triage : bool option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Topics = struct
                  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = {
                  allow_forking : bool option; [@default None]
                  allow_merge_commit : bool option; [@default None]
                  allow_rebase_merge : bool option; [@default None]
                  allow_squash_merge : bool option; [@default None]
                  archive_url : string;
                  archived : bool;
                  assignees_url : string;
                  blobs_url : string;
                  branches_url : string;
                  clone_url : string;
                  collaborators_url : string;
                  comments_url : string;
                  commits_url : string;
                  compare_url : string;
                  contents_url : string;
                  contributors_url : string;
                  created_at : string;
                  default_branch : string;
                  deployments_url : string;
                  description : string option;
                  disabled : bool;
                  downloads_url : string;
                  events_url : string;
                  fork : bool;
                  forks : int;
                  forks_count : int;
                  forks_url : string;
                  full_name : string;
                  git_commits_url : string;
                  git_refs_url : string;
                  git_tags_url : string;
                  git_url : string;
                  has_discussions : bool;
                  has_downloads : bool;
                  has_issues : bool;
                  has_pages : bool;
                  has_projects : bool;
                  has_wiki : bool;
                  homepage : string option;
                  hooks_url : string;
                  html_url : string;
                  id : int;
                  is_template : bool option; [@default None]
                  issue_comment_url : string;
                  issue_events_url : string;
                  issues_url : string;
                  keys_url : string;
                  labels_url : string;
                  language : string option;
                  languages_url : string;
                  license : License_.t option;
                  master_branch : string option; [@default None]
                  merges_url : string;
                  milestones_url : string;
                  mirror_url : string option;
                  name : string;
                  node_id : string;
                  notifications_url : string;
                  open_issues : int;
                  open_issues_count : int;
                  owner : Owner.t;
                  permissions : Permissions.t option; [@default None]
                  private_ : bool; [@key "private"]
                  pulls_url : string;
                  pushed_at : string;
                  releases_url : string;
                  size : int;
                  ssh_url : string;
                  stargazers_count : int;
                  stargazers_url : string;
                  statuses_url : string;
                  subscribers_url : string;
                  subscription_url : string;
                  svn_url : string;
                  tags_url : string;
                  teams_url : string;
                  temp_clone_token : string option; [@default None]
                  topics : Topics.t option; [@default None]
                  trees_url : string;
                  updated_at : string;
                  url : string;
                  visibility : string option; [@default None]
                  watchers : int;
                  watchers_count : int;
                  web_commit_signoff_required : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module User = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              label : string;
              ref_ : string; [@key "ref"]
              repo : Repo.t option;
              sha : string;
              user : User.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Labels = struct
          module Items = struct
            module Primary = struct
              type t = {
                color : string;
                default : bool;
                description : string option;
                id : int64;
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

        module Merge_commit_message = struct
          let t_of_yojson = function
            | `String "PR_BODY" -> Ok "PR_BODY"
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "BLANK" -> Ok "BLANK"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Merge_commit_title = struct
          let t_of_yojson = function
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "MERGE_MESSAGE" -> Ok "MERGE_MESSAGE"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Requested_reviewers = struct
          type t = Githubc2_components_simple_user.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Requested_teams = struct
          type t = Githubc2_components_team_simple.t list
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Squash_merge_commit_message = struct
          let t_of_yojson = function
            | `String "PR_BODY" -> Ok "PR_BODY"
            | `String "COMMIT_MESSAGES" -> Ok "COMMIT_MESSAGES"
            | `String "BLANK" -> Ok "BLANK"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Squash_merge_commit_title = struct
          let t_of_yojson = function
            | `String "PR_TITLE" -> Ok "PR_TITLE"
            | `String "COMMIT_OR_PR_TITLE" -> Ok "COMMIT_OR_PR_TITLE"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
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
          links_ : Links_.t; [@key "_links"]
          active_lock_reason : string option; [@default None]
          additions : int;
          allow_auto_merge : bool; [@default false]
          allow_update_branch : bool option; [@default None]
          assignee : Githubc2_components_nullable_simple_user.t option;
          assignees : Assignees.t option; [@default None]
          author_association : Githubc2_components_author_association.t;
          auto_merge : Githubc2_components_auto_merge.t option;
          base : Base.t;
          body : string option;
          changed_files : int;
          closed_at : string option;
          comments : int;
          comments_url : string;
          commits : int;
          commits_url : string;
          created_at : string;
          delete_branch_on_merge : bool; [@default false]
          deletions : int;
          diff_url : string;
          draft : bool option; [@default None]
          head : Head.t;
          html_url : string;
          id : int;
          issue_url : string;
          labels : Labels.t;
          locked : bool;
          maintainer_can_modify : bool;
          merge_commit_message : Merge_commit_message.t option; [@default None]
          merge_commit_sha : string option;
          merge_commit_title : Merge_commit_title.t option; [@default None]
          mergeable : bool option;
          mergeable_state : string;
          merged : bool;
          merged_at : string option;
          merged_by : Githubc2_components_nullable_simple_user.t option;
          milestone : Githubc2_components_nullable_milestone.t option;
          node_id : string;
          number : int;
          patch_url : string;
          rebaseable : bool option; [@default None]
          requested_reviewers : Requested_reviewers.t option; [@default None]
          requested_teams : Requested_teams.t option; [@default None]
          review_comment_url : string;
          review_comments : int;
          review_comments_url : string;
          squash_merge_commit_message : Squash_merge_commit_message.t option; [@default None]
          squash_merge_commit_title : Squash_merge_commit_title.t option; [@default None]
          state : State.t;
          statuses_url : string;
          title : string;
          updated_at : string;
          url : string;
          use_squash_pr_title_as_default : bool; [@default false]
          user : Githubc2_components_simple_user.t;
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
    number : int;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_request : Pull_request_.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
