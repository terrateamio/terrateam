module Primary = struct
  type t = {
    confirmed_at : string option; [@default None]
    email : string option; [@default None]
    id : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
