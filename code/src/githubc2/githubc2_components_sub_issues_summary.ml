module Primary = struct
  type t = {
    completed : int;
    percent_completed : int;
    total : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
