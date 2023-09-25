module Primary = struct
  module Forkee = struct
    module All_of = struct
      module Primary = struct
        module License_ = struct
          module Primary = struct
            type t = {
              key : string;
              name : string;
              node_id : string;
              spdx_id : string;
              url : string option;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

        module Visibility = struct
          let t_of_yojson = function
            | `String "public" -> Ok "public"
            | `String "private" -> Ok "private"
            | `String "internal" -> Ok "internal"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          allow_auto_merge : bool; [@default false]
          allow_forking : bool option; [@default None]
          allow_merge_commit : bool; [@default true]
          allow_rebase_merge : bool; [@default true]
          allow_squash_merge : bool; [@default true]
          allow_update_branch : bool option; [@default None]
          archive_url : string;
          archived : bool; [@default false]
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
          delete_branch_on_merge : bool; [@default false]
          deployments_url : string;
          description : string option;
          disabled : bool option; [@default None]
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
          has_downloads : bool; [@default true]
          has_issues : bool; [@default true]
          has_pages : bool;
          has_projects : bool; [@default true]
          has_wiki : bool; [@default true]
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
          organization : string option; [@default None]
          owner : Owner.t option;
          permissions : Permissions.t option; [@default None]
          private_ : bool; [@key "private"]
          public : bool option; [@default None]
          pulls_url : string;
          pushed_at : string option;
          releases_url : string;
          role_name : string option; [@default None]
          size : int;
          ssh_url : string;
          stargazers : int option; [@default None]
          stargazers_count : int;
          stargazers_url : string;
          statuses_url : string;
          subscribers_url : string;
          subscription_url : string;
          svn_url : string;
          tags_url : string;
          teams_url : string;
          topics : Topics.t;
          trees_url : string;
          updated_at : string;
          url : string;
          visibility : Visibility.t;
          watchers : int;
          watchers_count : int;
          web_commit_signoff_required : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module License_ = struct
          module Primary = struct
            type t = {
              key : string;
              name : string;
              node_id : string;
              spdx_id : string;
              url : string option;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

        module Visibility = struct
          let t_of_yojson = function
            | `String "public" -> Ok "public"
            | `String "private" -> Ok "private"
            | `String "internal" -> Ok "internal"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          allow_auto_merge : bool; [@default false]
          allow_forking : bool option; [@default None]
          allow_merge_commit : bool; [@default true]
          allow_rebase_merge : bool; [@default true]
          allow_squash_merge : bool; [@default true]
          allow_update_branch : bool option; [@default None]
          archive_url : string;
          archived : bool; [@default false]
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
          delete_branch_on_merge : bool; [@default false]
          deployments_url : string;
          description : string option;
          disabled : bool option; [@default None]
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
          has_downloads : bool; [@default true]
          has_issues : bool; [@default true]
          has_pages : bool;
          has_projects : bool; [@default true]
          has_wiki : bool; [@default true]
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
          organization : string option; [@default None]
          owner : Owner.t option;
          permissions : Permissions.t option; [@default None]
          private_ : bool; [@key "private"]
          public : bool option; [@default None]
          pulls_url : string;
          pushed_at : string option;
          releases_url : string;
          role_name : string option; [@default None]
          size : int;
          ssh_url : string;
          stargazers : int option; [@default None]
          stargazers_count : int;
          stargazers_url : string;
          statuses_url : string;
          subscribers_url : string;
          subscription_url : string;
          svn_url : string;
          tags_url : string;
          teams_url : string;
          topics : Topics.t;
          trees_url : string;
          updated_at : string;
          url : string;
          visibility : Visibility.t;
          watchers : int;
          watchers_count : int;
          web_commit_signoff_required : bool option; [@default None]
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
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    forkee : Forkee.t;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
