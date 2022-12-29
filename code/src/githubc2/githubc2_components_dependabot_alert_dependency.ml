module Primary = struct
  type t = {
    manifest_path : string option; [@default None]
    package : Githubc2_components_dependabot_alert_package.t option; [@default None]
    scope : Githubc2_components_dependabot_alert_scope.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
