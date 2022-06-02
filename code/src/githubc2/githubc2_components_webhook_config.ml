module Primary = struct
  type t = {
    content_type : string option; [@default None]
    insecure_ssl : Githubc2_components_webhook_config_insecure_ssl.t option; [@default None]
    secret : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
