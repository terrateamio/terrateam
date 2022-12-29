module Primary = struct
  type t = {
    allowed_actions : Githubc2_components_allowed_actions.t option; [@default None]
    enabled_repositories : Githubc2_components_enabled_repositories.t;
    selected_actions_url : string option; [@default None]
    selected_repositories_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
