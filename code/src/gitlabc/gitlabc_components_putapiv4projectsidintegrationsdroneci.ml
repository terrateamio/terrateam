module Primary = struct
  type t = {
    drone_url : string;
    enable_ssl_verification : bool option; [@default None]
    merge_requests_events : bool option; [@default None]
    push_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    token : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
