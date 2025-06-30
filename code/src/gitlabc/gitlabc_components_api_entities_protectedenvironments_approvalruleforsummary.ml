module Primary = struct
  type t = {
    access_level : string option; [@default None]
    access_level_description : string option; [@default None]
    deployment_approvals : Gitlabc_components_api_entities_deployments_approval.t option;
        [@default None]
    group_id : string option; [@default None]
    group_inheritance_type : string option; [@default None]
    id : string option; [@default None]
    required_approvals : string option; [@default None]
    user_id : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
