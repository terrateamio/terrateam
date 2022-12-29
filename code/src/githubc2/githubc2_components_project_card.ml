module Primary = struct
  type t = {
    archived : bool option; [@default None]
    column_name : string option; [@default None]
    column_url : string;
    content_url : string option; [@default None]
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option;
    id : int;
    node_id : string;
    note : string option;
    project_id : string option; [@default None]
    project_url : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
