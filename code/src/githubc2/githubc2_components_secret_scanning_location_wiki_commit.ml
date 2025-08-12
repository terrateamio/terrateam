module Primary = struct
  type t = {
    blob_sha : string;
    commit_sha : string;
    commit_url : string;
    end_column : float;
    end_line : float;
    page_url : string;
    path : string;
    start_column : float;
    start_line : float;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
