module Primary = struct
  type t = {
    total_count : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show]
end

module Additional = struct
  type t = int [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Additional)
