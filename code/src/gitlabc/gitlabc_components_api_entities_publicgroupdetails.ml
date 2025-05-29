module Primary = struct
  type t = {
    avatar_url : string option; [@default None]
    full_name : string option; [@default None]
    full_path : string option; [@default None]
    id : string option; [@default None]
    name : string option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
