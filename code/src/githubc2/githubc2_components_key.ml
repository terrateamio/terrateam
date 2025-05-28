module Primary = struct
  type t = {
    created_at : string;
    id : int64;
    key : string;
    read_only : bool;
    title : string;
    url : string;
    verified : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
