module Primary = struct
  type t = {
    time : string option; [@default None] [@key "Time"]
    version : string option; [@default None] [@key "Version"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
