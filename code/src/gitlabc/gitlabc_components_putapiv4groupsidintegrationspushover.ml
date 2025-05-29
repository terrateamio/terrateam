module Primary = struct
  type t = {
    api_key : string;
    device : string option; [@default None]
    priority : string;
    push_events : bool option; [@default None]
    sound : string option; [@default None]
    use_inherited_settings : bool option; [@default None]
    user_key : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
