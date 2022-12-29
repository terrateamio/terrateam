module Primary = struct
  type t = {
    allowed_actions : Githubc2_components_allowed_actions.t option; [@default None]
    enabled_organizations : Githubc2_components_enabled_organizations.t;
    selected_actions_url : string option; [@default None]
    selected_organizations_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
