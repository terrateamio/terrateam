module Inputs = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  inputs : Inputs.t option; [@default None]
  ref_ : string; [@key "ref"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
