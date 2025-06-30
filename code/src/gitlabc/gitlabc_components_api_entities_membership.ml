module Primary = struct
  type t = {
    access_level : string option; [@default None]
    source_id : string option; [@default None]
    source_name : string option; [@default None]
    source_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
