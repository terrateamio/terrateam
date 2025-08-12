module Dist_tags = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

module Versions = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  dist_tags : Dist_tags.t option; [@default None] [@key "dist-tags"]
  name : string option; [@default None]
  versions : Versions.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
