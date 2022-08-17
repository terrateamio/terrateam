module Primary = struct
  type t = {
    id : int;
    is_alphanumeric : bool option; [@default None]
    key_prefix : string;
    url_template : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
