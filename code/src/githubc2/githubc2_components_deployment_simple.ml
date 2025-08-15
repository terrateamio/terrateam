module Primary = struct
  type t = {
    created_at : string;
    description : string option; [@default None]
    environment : string;
    id : int;
    node_id : string;
    original_environment : string option; [@default None]
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    production_environment : bool option; [@default None]
    repository_url : string;
    statuses_url : string;
    task : string;
    transient_environment : bool option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
