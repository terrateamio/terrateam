module Primary = struct
  type t = {
    access_level : string option; [@default None]
    notification_level : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
