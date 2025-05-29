module Primary = struct
  type t = {
    id : string option; [@default None]
    token : string option; [@default None]
    token_expires_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
