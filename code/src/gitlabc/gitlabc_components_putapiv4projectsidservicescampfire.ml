module Primary = struct
  type t = {
    push_events : bool option; [@default None]
    room : string option; [@default None]
    subdomain : string option; [@default None]
    token : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
