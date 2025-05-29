module Primary = struct
  type t = {
    html_url : string option; [@default None]
    key : string option; [@default None]
    name : string option; [@default None]
    nickname : string option; [@default None]
    source_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
