module Primary = struct
  type t = {
    count : int;
    path : string;
    title : string;
    uniques : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
