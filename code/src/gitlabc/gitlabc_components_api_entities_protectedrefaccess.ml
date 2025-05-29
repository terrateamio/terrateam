module Primary = struct
  type t = {
    access_level : int option; [@default None]
    access_level_description : string option; [@default None]
    deploy_key_id : int option; [@default None]
    group_id : int option; [@default None]
    id : int option; [@default None]
    user_id : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
