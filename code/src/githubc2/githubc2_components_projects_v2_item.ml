module Primary = struct
  type t = {
    archived_at : string option; [@default None]
    content_node_id : string;
    content_type : Githubc2_components_projects_v2_item_content_type.t;
    created_at : string;
    creator : Githubc2_components_simple_user.t option; [@default None]
    id : float;
    node_id : string option; [@default None]
    project_node_id : string option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
