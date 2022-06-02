module Primary = struct
  module Views = struct
    type t = Githubc2_components_traffic.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    count : int;
    uniques : int;
    views : Views.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
