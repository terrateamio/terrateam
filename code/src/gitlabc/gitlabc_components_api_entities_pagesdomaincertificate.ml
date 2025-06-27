module Primary = struct
  type t = {
    certificate : string option; [@default None]
    certificate_text : string option; [@default None]
    expired : string option; [@default None]
    subject : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
