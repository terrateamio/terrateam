module Items = struct
  module Primary = struct
    module Dormant_users = struct
      module Primary = struct
        type t = {
          dormancy_threshold : string option; [@default None]
          total_dormant_users : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Ghe_stats = struct
      module Primary = struct
        module Comments = struct
          module Primary = struct
            type t = {
              total_commit_comments : int option; [@default None]
              total_gist_comments : int option; [@default None]
              total_issue_comments : int option; [@default None]
              total_pull_request_comments : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Gists = struct
          module Primary = struct
            type t = {
              private_gists : int option; [@default None]
              public_gists : int option; [@default None]
              total_gists : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Hooks = struct
          module Primary = struct
            type t = {
              active_hooks : int option; [@default None]
              inactive_hooks : int option; [@default None]
              total_hooks : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Issues = struct
          module Primary = struct
            type t = {
              closed_issues : int option; [@default None]
              open_issues : int option; [@default None]
              total_issues : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Milestones = struct
          module Primary = struct
            type t = {
              closed_milestones : int option; [@default None]
              open_milestones : int option; [@default None]
              total_milestones : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Orgs = struct
          module Primary = struct
            type t = {
              disabled_orgs : int option; [@default None]
              total_orgs : int option; [@default None]
              total_team_members : int option; [@default None]
              total_teams : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Pages = struct
          module Primary = struct
            type t = { total_pages : int option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Pulls = struct
          module Primary = struct
            type t = {
              mergeable_pulls : int option; [@default None]
              merged_pulls : int option; [@default None]
              total_pulls : int option; [@default None]
              unmergeable_pulls : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Repos = struct
          module Primary = struct
            type t = {
              fork_repos : int option; [@default None]
              org_repos : int option; [@default None]
              root_repos : int option; [@default None]
              total_pushes : int option; [@default None]
              total_repos : int option; [@default None]
              total_wikis : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Users = struct
          module Primary = struct
            type t = {
              admin_users : int option; [@default None]
              suspended_users : int option; [@default None]
              total_users : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          comments : Comments.t option; [@default None]
          gists : Gists.t option; [@default None]
          hooks : Hooks.t option; [@default None]
          issues : Issues.t option; [@default None]
          milestones : Milestones.t option; [@default None]
          orgs : Orgs.t option; [@default None]
          pages : Pages.t option; [@default None]
          pulls : Pulls.t option; [@default None]
          repos : Repos.t option; [@default None]
          users : Users.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Github_connect = struct
      module Primary = struct
        module Features_enabled = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { features_enabled : Features_enabled.t option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      collection_date : string option; [@default None]
      dormant_users : Dormant_users.t option; [@default None]
      ghe_stats : Ghe_stats.t option; [@default None]
      ghes_version : string option; [@default None]
      github_connect : Github_connect.t option; [@default None]
      host_name : string option; [@default None]
      schema_version : string option; [@default None]
      server_id : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
