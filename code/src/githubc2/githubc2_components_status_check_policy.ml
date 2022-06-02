module Primary = struct
  module Contexts = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    contexts : Contexts.t;
    contexts_url : string;
    strict : bool;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
