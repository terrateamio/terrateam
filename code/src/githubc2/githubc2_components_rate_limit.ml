module Primary = struct
  type t = {
    limit : int;
    remaining : int;
    reset : int;
    used : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
