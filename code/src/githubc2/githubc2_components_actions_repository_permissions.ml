module Primary = struct
  type t = {
    allowed_actions : Githubc2_components_allowed_actions.t option; [@default None]
    enabled : bool;
    selected_actions_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
