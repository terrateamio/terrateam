module Primary = struct
  module Account = struct
    module Primary = struct
      module Description = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Website_url = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        archived_at : string option; [@default None]
        avatar_url : string;
        created_at : string option; [@default None]
        description : Description.t option; [@default None]
        events_url : string option; [@default None]
        followers : int option; [@default None]
        followers_url : string option; [@default None]
        following : int option; [@default None]
        following_url : string option; [@default None]
        gists_url : string option; [@default None]
        gravatar_id : string option; [@default None]
        has_organization_projects : bool option; [@default None]
        has_repository_projects : bool option; [@default None]
        hooks_url : string option; [@default None]
        html_url : string;
        id : int;
        is_verified : bool option; [@default None]
        issues_url : string option; [@default None]
        login : string option; [@default None]
        members_url : string option; [@default None]
        name : string option; [@default None]
        node_id : string;
        organizations_url : string option; [@default None]
        public_gists : int option; [@default None]
        public_members_url : string option; [@default None]
        public_repos : int option; [@default None]
        received_events_url : string option; [@default None]
        repos_url : string option; [@default None]
        site_admin : bool option; [@default None]
        slug : string option; [@default None]
        starred_url : string option; [@default None]
        subscriptions_url : string option; [@default None]
        type_ : string option; [@default None] [@key "type"]
        updated_at : string option; [@default None]
        url : string option; [@default None]
        website_url : Website_url.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Action = struct
    let t_of_yojson = function
      | `String "renamed" -> Ok "renamed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Login = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Slug = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        login : Login.t option; [@default None]
        slug : Slug.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    account : Account.t;
    action : Action.t;
    changes : Changes.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user_webhooks.t option; [@default None]
    target_type : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
