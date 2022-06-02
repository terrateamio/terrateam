module Primary = struct
  type t = {
    archive_download_url : string;
    created_at : string option;
    expired : bool;
    expires_at : string option;
    id : int;
    name : string;
    node_id : string;
    size_in_bytes : int;
    updated_at : string option;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
