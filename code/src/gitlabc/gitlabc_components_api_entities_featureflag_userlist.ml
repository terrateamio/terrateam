module Primary = struct
  type t = {
    created_at : string option; [@default None]
    edit_path : string option; [@default None]
    id : int option; [@default None]
    iid : int option; [@default None]
    name : string option; [@default None]
    path : string option; [@default None]
    project_id : int option; [@default None]
    updated_at : string option; [@default None]
    user_xids : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
