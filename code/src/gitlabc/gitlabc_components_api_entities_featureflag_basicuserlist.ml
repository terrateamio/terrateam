module Primary = struct
  type t = {
    id : int option; [@default None]
    iid : int option; [@default None]
    name : string option; [@default None]
    user_xids : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
