module Primary = struct
  type t = {
    created_at : string option; [@default None]
    exception_class : string option; [@default None]
    exception_message : string option; [@default None]
    id : string option; [@default None]
    line_number : int option; [@default None]
    relation_name : string option; [@default None]
    source : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
