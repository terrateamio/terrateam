module Additional = struct
  type t = int [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
