module Package_snapshot = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = { package_snapshot : Package_snapshot.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
