module Primary = struct
  type t = {
    akismet_submitted : bool option; [@default None]
    ip_address : string option; [@default None]
    user_agent : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
