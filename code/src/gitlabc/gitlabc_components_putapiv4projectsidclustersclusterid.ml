module Platform_kubernetes_attributes = struct
  module Primary = struct
    type t = {
      api_url : string option; [@default None]
      ca_cert : string option; [@default None]
      namespace : string option; [@default None]
      token : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  domain : string option; [@default None]
  enabled : bool option; [@default None]
  environment_scope : string option; [@default None]
  managed : bool option; [@default None]
  management_project_id : int option; [@default None]
  name : string option; [@default None]
  namespace_per_environment : bool; [@default true]
  platform_kubernetes_attributes : Platform_kubernetes_attributes.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
