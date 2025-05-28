module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "updated" -> Ok "updated"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module New_property_values = struct
    type t = Githubc2_components_custom_property_value.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Old_property_values = struct
    type t = Githubc2_components_custom_property_value.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    new_property_values : New_property_values.t;
    old_property_values : Old_property_values.t;
    organization : Githubc2_components_organization_simple_webhooks.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
