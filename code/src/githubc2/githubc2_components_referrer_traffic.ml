module Primary = struct
  type t = {
    count : int;
    referrer : string;
    uniques : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
