module Primary = struct
  module Days = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    days : Days.t;
    total : int;
    week : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
