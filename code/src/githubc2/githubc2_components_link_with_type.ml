module Primary = struct
  type t = {
    href : string;
    type_ : string; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
