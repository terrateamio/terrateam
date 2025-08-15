module Primary = struct
  type t = {
    annotation_level : string option; [@default None]
    blob_href : string;
    end_column : int option; [@default None]
    end_line : int;
    message : string option; [@default None]
    path : string;
    raw_details : string option; [@default None]
    start_column : int option; [@default None]
    start_line : int;
    title : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
