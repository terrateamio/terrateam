module Primary = struct
  type t = {
    from : string;
    to_ : string; [@key "to"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
