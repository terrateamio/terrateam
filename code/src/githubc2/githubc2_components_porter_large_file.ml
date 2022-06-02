module Primary = struct
  type t = {
    oid : string;
    path : string;
    ref_name : string;
    size : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
