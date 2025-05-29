module Primary = struct
  type t = {
    cluster_type : string option; [@default None]
    created_at : string option; [@default None]
    domain : string option; [@default None]
    enabled : string option; [@default None]
    environment_scope : string option; [@default None]
    id : string option; [@default None]
    managed : string option; [@default None]
    management_project : Gitlabc_components_api_entities_projectidentity.t option; [@default None]
    name : string option; [@default None]
    namespace_per_environment : string option; [@default None]
    platform_kubernetes : Gitlabc_components_api_entities_platform_kubernetes.t option;
        [@default None]
    platform_type : string option; [@default None]
    provider_gcp : Gitlabc_components_api_entities_provider_gcp.t option; [@default None]
    provider_type : string option; [@default None]
    user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
