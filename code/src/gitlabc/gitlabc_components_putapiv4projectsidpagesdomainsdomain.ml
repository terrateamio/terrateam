module Primary = struct
  type t = {
    auto_ssl_enabled : bool option; [@default None]
    certificate : string option; [@default None]
    key : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
