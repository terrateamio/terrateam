module Items = struct
  module Primary = struct
    type t = {
      full_name : string;
      id : int;
      name : string;
      node_id : string;
      private_ : bool; [@key "private"]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
