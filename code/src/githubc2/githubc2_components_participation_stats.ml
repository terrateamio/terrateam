module Primary = struct
  module All = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Owner = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    all : All.t;
    owner : Owner.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
