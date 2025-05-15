module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "resolved" -> Ok "resolved"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_request_ = struct
    module Primary = struct
      module Links_ = struct
        module Primary = struct
          module Comments = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Commits = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Html = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Issue_ = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Review_comment_ = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Review_comments = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Self = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Statuses = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            comments : Comments.t;
            commits : Commits.t;
            html : Html.t;
            issue : Issue_.t;
            review_comment : Review_comment_.t;
            review_comments : Review_comments.t;
            self : Self.t;
            statuses : Statuses.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

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

      module Assignees = struct
        module Items = struct
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

      module Auto_merge_ = struct
        module Primary = struct
          module Enabled_by = struct
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

          module Merge_method = struct
            let t_of_yojson = function
              | `String "merge" -> Ok "merge"
              | `String "squash" -> Ok "squash"
              | `String "rebase" -> Ok "rebase"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            commit_message : string option;
            commit_title : string option;
            enabled_by : Enabled_by.t option;
            merge_method : Merge_method.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Base = struct
        module Primary = struct
          module Repo = struct
            module Primary = struct
              module Created_at = struct
                module V0 = struct
                  type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
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
                    user_view_type : string option; [@default None]
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

              module Pushed_at = struct
                module V0 = struct
                  type t = int option [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
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
                created_at : Created_at.t;
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
                has_discussions : bool; [@default false]
                has_downloads : bool; [@default true]
                has_issues : bool; [@default true]
                has_pages : bool;
                has_projects : bool; [@default true]
                has_wiki : bool; [@default true]
                homepage : string option;
                hooks_url : string;
                html_url : string;
                id : int64;
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
                pushed_at : Pushed_at.t option;
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

          module User = struct
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
            label : string;
            ref_ : string; [@key "ref"]
            repo : Repo.t;
            sha : string;
            user : User.t option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Head = struct
        module Primary = struct
          module Repo = struct
            module Primary = struct
              module Created_at = struct
                module V0 = struct
                  type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
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
                    user_view_type : string option; [@default None]
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

              module Pushed_at = struct
                module V0 = struct
                  type t = int option [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
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
                created_at : Created_at.t;
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
                has_discussions : bool; [@default false]
                has_downloads : bool; [@default true]
                has_issues : bool; [@default true]
                has_pages : bool;
                has_projects : bool; [@default true]
                has_wiki : bool; [@default true]
                homepage : string option;
                hooks_url : string;
                html_url : string;
                id : int64;
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
                pushed_at : Pushed_at.t option;
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

          module User = struct
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
            label : string option;
            ref_ : string; [@key "ref"]
            repo : Repo.t option;
            sha : string;
            user : User.t option;
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

      module Requested_reviewers = struct
        module Items = struct
          module V0 = struct
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
                user_view_type : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module V1 = struct
            module Primary = struct
              module Parent = struct
                module Primary = struct
                  module Privacy = struct
                    let t_of_yojson = function
                      | `String "open" -> Ok "open"
                      | `String "closed" -> Ok "closed"
                      | `String "secret" -> Ok "secret"
                      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                    type t = (string[@of_yojson t_of_yojson])
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  type t = {
                    description : string option;
                    html_url : string;
                    id : int;
                    members_url : string;
                    name : string;
                    node_id : string;
                    permission : string;
                    privacy : Privacy.t;
                    repositories_url : string;
                    slug : string;
                    url : string;
                  }
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              module Privacy = struct
                let t_of_yojson = function
                  | `String "open" -> Ok "open"
                  | `String "closed" -> Ok "closed"
                  | `String "secret" -> Ok "secret"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                deleted : bool option; [@default None]
                description : string option;
                html_url : string;
                id : int;
                members_url : string;
                name : string;
                node_id : string;
                parent : Parent.t option; [@default None]
                permission : string;
                privacy : Privacy.t;
                repositories_url : string;
                slug : string;
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Requested_teams = struct
        module Items = struct
          module Primary = struct
            module Parent = struct
              module Primary = struct
                module Privacy = struct
                  let t_of_yojson = function
                    | `String "open" -> Ok "open"
                    | `String "closed" -> Ok "closed"
                    | `String "secret" -> Ok "secret"
                    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                  type t = (string[@of_yojson t_of_yojson])
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = {
                  description : string option;
                  html_url : string;
                  id : int;
                  members_url : string;
                  name : string;
                  node_id : string;
                  permission : string;
                  privacy : Privacy.t;
                  repositories_url : string;
                  slug : string;
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Privacy = struct
              let t_of_yojson = function
                | `String "open" -> Ok "open"
                | `String "closed" -> Ok "closed"
                | `String "secret" -> Ok "secret"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              deleted : bool option; [@default None]
              description : string option; [@default None]
              html_url : string option; [@default None]
              id : int;
              members_url : string option; [@default None]
              name : string;
              node_id : string option; [@default None]
              parent : Parent.t option; [@default None]
              permission : string option; [@default None]
              privacy : Privacy.t option; [@default None]
              repositories_url : string option; [@default None]
              slug : string option; [@default None]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
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
        links_ : Links_.t; [@key "_links"]
        active_lock_reason : Active_lock_reason.t option;
        assignee : Assignee.t option;
        assignees : Assignees.t;
        author_association : Author_association_.t;
        auto_merge : Auto_merge_.t option;
        base : Base.t;
        body : string option;
        closed_at : string option;
        comments_url : string;
        commits_url : string;
        created_at : string;
        diff_url : string;
        draft : bool;
        head : Head.t;
        html_url : string;
        id : int;
        issue_url : string;
        labels : Labels.t;
        locked : bool;
        merge_commit_sha : string option;
        merged_at : string option;
        milestone : Milestone_.t option;
        node_id : string;
        number : int;
        patch_url : string;
        requested_reviewers : Requested_reviewers.t;
        requested_teams : Requested_teams.t;
        review_comment_url : string;
        review_comments_url : string;
        state : State.t;
        statuses_url : string;
        title : string;
        updated_at : string;
        url : string;
        user : User.t option;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Thread_ = struct
    module Primary = struct
      module Comments = struct
        module Items = struct
          module Primary = struct
            module Links_ = struct
              module Primary = struct
                module Html = struct
                  module Primary = struct
                    type t = { href : string }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Pull_request_ = struct
                  module Primary = struct
                    type t = { href : string }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                module Self = struct
                  module Primary = struct
                    type t = { href : string }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = {
                  html : Html.t;
                  pull_request : Pull_request_.t;
                  self : Self.t;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

            module Side = struct
              let t_of_yojson = function
                | `String "LEFT" -> Ok "LEFT"
                | `String "RIGHT" -> Ok "RIGHT"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Start_side = struct
              let t_of_yojson = function
                | `String "LEFT" -> Ok "LEFT"
                | `String "RIGHT" -> Ok "RIGHT"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Subject_type = struct
              let t_of_yojson = function
                | `String "line" -> Ok "line"
                | `String "file" -> Ok "file"
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
              links_ : Links_.t; [@key "_links"]
              author_association : Author_association_.t;
              body : string;
              commit_id : string;
              created_at : string;
              diff_hunk : string;
              html_url : string;
              id : int;
              in_reply_to_id : int option; [@default None]
              line : int option;
              node_id : string;
              original_commit_id : string;
              original_line : int option;
              original_position : int;
              original_start_line : int option;
              path : string;
              position : int option;
              pull_request_review_id : int option;
              pull_request_url : string;
              reactions : Reactions.t;
              side : Side.t;
              start_line : int option;
              start_side : Start_side.t option; [@default Some "RIGHT"]
              subject_type : Subject_type.t option; [@default None]
              updated_at : string;
              url : string;
              user : User.t option;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        comments : Comments.t;
        node_id : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_request : Pull_request_.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t option; [@default None]
    thread : Thread_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
