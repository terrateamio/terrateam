module Primary = struct
  type t = {
    blob_sha : string;
    blob_url : string;
    commit_sha : string;
    commit_url : string;
    end_column : float;
    end_line : float;
    path : string;
    start_column : float;
    start_line : float;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
