module Primary = struct
  type t = {
    architecture : string option; [@default None]
    contacted_at : string option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    ip_address : string option; [@default None]
    platform : string option; [@default None]
    revision : string option; [@default None]
    status : string option; [@default None]
    system_id : string option; [@default None]
    version : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
