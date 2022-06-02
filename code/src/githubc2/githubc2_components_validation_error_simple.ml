module Primary = struct
  module Errors = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    documentation_url : string;
    errors : Errors.t option; [@default None]
    message : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
