module Primary = struct
  type t = {
    jira_cloud_app_deployment_gating_environments : string option; [@default None]
    jira_cloud_app_enable_deployment_gating : bool option; [@default None]
    jira_cloud_app_service_ids : string option; [@default None]
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
