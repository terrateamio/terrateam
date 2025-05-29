module Primary = struct
  type t = {
    approval_password : string option; [@default None]
    sha : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
