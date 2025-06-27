module Primary = struct
  type t = {
    created_at : string option; [@default None]
    id : int option; [@default None]
    key : string option; [@default None]
    title : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
