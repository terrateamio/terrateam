module Primary = struct
  type t = {
    created_at : string option; [@default None]
    html_url : string option; [@default None]
    locations_url : string option; [@default None]
    number : int option; [@default None]
    repository : Githubc2_components_minimal_repository.t option; [@default None]
    resolution : Githubc2_components_secret_scanning_alert_resolution.t option; [@default None]
    resolved_at : string option; [@default None]
    resolved_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    secret : string option; [@default None]
    secret_type : string option; [@default None]
    state : Githubc2_components_secret_scanning_alert_state.t option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)