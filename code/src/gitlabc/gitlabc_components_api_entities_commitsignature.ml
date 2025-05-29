module Primary = struct
  type t = {
    commit_source : string option; [@default None]
    signature : string option; [@default None]
    signature_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
