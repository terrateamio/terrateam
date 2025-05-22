module Primary = struct
  type t = {
    path : string;
    ref_ : string option; [@default None] [@key "ref"]
    repository_id : int;
    sha : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
