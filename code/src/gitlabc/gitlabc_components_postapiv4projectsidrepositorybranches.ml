module Primary = struct
  type t = {
    branch : string;
    ref_ : string; [@key "ref"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
