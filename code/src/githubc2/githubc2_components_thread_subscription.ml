module Primary = struct
  type t = {
    created_at : string option; [@default None]
    ignored : bool;
    reason : string option; [@default None]
    repository_url : string option; [@default None]
    subscribed : bool;
    thread_url : string option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
