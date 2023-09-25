module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "edited" -> Ok "edited"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Old_permission = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Permission = struct
        module Primary = struct
          type t = {
            from : string option; [@default None]
            to_ : string option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        old_permission : Old_permission.t option; [@default None]
        permission : Permission.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Member = struct
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
    action : Action.t;
    changes : Changes.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    member : Member.t option;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
