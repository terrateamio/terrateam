module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "archived" -> Ok "archived"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Archived_at = struct
        module Primary = struct
          type t = {
            from : string option; [@default None]
            to_ : string option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { archived_at : Archived_at.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t;
    projects_v2_item : Githubc2_components_projects_v2_item.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
