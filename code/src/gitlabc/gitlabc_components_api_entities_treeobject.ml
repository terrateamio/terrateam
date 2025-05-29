module Primary = struct
  type t = {
    id : string option; [@default None]
    mode : string option; [@default None]
    name : string option; [@default None]
    path : string option; [@default None]
    type_ : string option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
