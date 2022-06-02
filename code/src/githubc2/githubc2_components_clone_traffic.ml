module Primary = struct
  module Clones = struct
    type t = Githubc2_components_traffic.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    clones : Clones.t;
    count : int;
    uniques : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
