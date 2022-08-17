module Primary = struct
  type t = { include_enterprise_slug : bool option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
