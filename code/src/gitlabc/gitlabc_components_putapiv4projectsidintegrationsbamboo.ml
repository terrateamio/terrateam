module Primary = struct
  type t = {
    bamboo_url : string;
    build_key : string;
    enable_ssl_verification : bool option; [@default None]
    password : string;
    push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
    username : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
