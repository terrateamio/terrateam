module Primary = struct
  type t = {
    format : string option; [@default None]
    slug : string option; [@default None]
    title : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
