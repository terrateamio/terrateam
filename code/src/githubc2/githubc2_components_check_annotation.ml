module Primary = struct
  type t = {
    annotation_level : string option;
    blob_href : string;
    end_column : int option;
    end_line : int;
    message : string option;
    path : string;
    raw_details : string option;
    start_column : int option;
    start_line : int;
    title : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
