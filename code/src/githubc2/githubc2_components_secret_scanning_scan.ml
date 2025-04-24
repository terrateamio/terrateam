module Primary = struct
  type t = {
    completed_at : string option; [@default None]
    started_at : string option; [@default None]
    status : string option; [@default None]
    type_ : string option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
