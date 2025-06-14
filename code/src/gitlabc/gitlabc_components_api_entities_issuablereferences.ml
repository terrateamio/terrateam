module Primary = struct
  type t = {
    full : string option; [@default None]
    relative : string option; [@default None]
    short : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
