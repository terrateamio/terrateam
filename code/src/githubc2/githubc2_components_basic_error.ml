module Primary = struct
  type t = {
    documentation_url : string option; [@default None]
    message : string option; [@default None]
    status : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
