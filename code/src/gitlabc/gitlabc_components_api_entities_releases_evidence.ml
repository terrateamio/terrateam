module Primary = struct
  type t = {
    collected_at : string option; [@default None]
    filepath : string option; [@default None]
    sha : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
