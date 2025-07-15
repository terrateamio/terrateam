module Versions = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = { versions : Versions.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
