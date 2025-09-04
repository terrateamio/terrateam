module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "added" -> Ok "added"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repositories_removed = struct
    module Items = struct
      module Primary = struct
        type t = {
          full_name : string option; [@default None]
          id : int option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          private_ : bool option; [@default None] [@key "private"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_installation.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repositories_added : Githubc2_components_webhooks_repositories_added.t;
    repositories_removed : Repositories_removed.t;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    repository_selection : Githubc2_components_webhooks_repository_selection.t;
    requester : Githubc2_components_webhooks_user.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
