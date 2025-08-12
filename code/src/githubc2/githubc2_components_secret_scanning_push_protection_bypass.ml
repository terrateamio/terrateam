module Primary = struct
  type t = {
    expire_at : string option; [@default None]
    reason : Githubc2_components_secret_scanning_push_protection_bypass_reason.t option;
        [@default None]
    token_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
