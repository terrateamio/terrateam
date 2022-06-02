module Primary = struct
  type t = {
    created_at : string;
    ignored : bool;
    reason : string option;
    repository_url : string;
    subscribed : bool;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
