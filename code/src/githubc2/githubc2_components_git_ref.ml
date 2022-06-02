module Primary = struct
  module Object = struct
    module Primary = struct
      type t = {
        sha : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    node_id : string;
    object_ : Object.t; [@key "object"]
    ref_ : string; [@key "ref"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
