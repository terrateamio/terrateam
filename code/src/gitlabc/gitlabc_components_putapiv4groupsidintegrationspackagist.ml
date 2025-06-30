module Primary = struct
  type t = {
    merge_requests_events : bool option; [@default None]
    push_events : bool option; [@default None]
    server : string option; [@default None]
    tag_push_events : bool option; [@default None]
    token : string;
    use_inherited_settings : bool option; [@default None]
    username : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
