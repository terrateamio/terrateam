module Metadata = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  metadata : Metadata.t;
  version : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
