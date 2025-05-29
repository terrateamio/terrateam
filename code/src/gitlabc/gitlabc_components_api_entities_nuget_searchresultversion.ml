module Primary = struct
  type t = {
    id_ : string option; [@default None] [@key "@id"]
    downloads : int option; [@default None]
    version : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
