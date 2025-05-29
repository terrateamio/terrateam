module Primary = struct
  type t = {
    access_level : int option; [@default None]
    expires_at : string option; [@default None]
    member_role_id : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
