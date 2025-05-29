module Primary = struct
  type t = {
    application_id : string option; [@default None]
    application_name : string option; [@default None]
    callback_url : string option; [@default None]
    confidential : bool option; [@default None]
    id : string option; [@default None]
    secret : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
