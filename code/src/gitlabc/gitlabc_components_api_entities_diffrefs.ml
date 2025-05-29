module Primary = struct
  type t = {
    base_sha : string option; [@default None]
    head_sha : string option; [@default None]
    start_sha : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
