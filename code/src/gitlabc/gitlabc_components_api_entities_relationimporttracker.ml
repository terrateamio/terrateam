module Primary = struct
  type t = {
    created_at : string option; [@default None]
    id : int option; [@default None]
    project_path : string option; [@default None]
    relation : string option; [@default None]
    status : string option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
