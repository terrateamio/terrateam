module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "suspend" -> Ok "suspend"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repositories = struct
    module Items = struct
      module Primary = struct
        type t = {
          full_name : string;
          id : int;
          name : string;
          node_id : string;
          private_ : bool; [@key "private"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Requester = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_installation.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repositories : Repositories.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    requester : Requester.t option; [@default None]
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
