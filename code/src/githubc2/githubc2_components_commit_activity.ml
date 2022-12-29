module Primary = struct
  module Days = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    days : Days.t;
    total : int;
    week : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
