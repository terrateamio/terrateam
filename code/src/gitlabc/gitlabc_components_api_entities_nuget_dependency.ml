module Primary = struct
  type t = {
    id_ : string option; [@default None] [@key "@id"]
    type_ : string option; [@default None] [@key "@type"]
    id : string option; [@default None]
    range : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
