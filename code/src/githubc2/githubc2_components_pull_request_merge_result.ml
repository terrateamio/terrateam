module Primary = struct
  type t = {
    merged : bool;
    message : string;
    sha : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
