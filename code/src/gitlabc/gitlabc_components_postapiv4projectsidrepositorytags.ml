module Primary = struct
  type t = {
    message : string option; [@default None]
    ref_ : string; [@key "ref"]
    tag_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
