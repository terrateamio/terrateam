module Primary = struct
  type t = {
    auto_ssl_enabled : bool; [@default false]
    certificate : string option; [@default None]
    domain : string;
    key : string option; [@default None]
    user_provided_certificate : string option; [@default None]
    user_provided_key : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
