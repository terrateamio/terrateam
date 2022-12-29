module Primary = struct
  type t = {
    total_count : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Additional = struct
  type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Additional)
