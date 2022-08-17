module Primary = struct
  type t = {
    path : string;
    ref_ : string option; [@default None] [@key "ref"]
    sha : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
