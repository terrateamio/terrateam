module Platform_kubernetes_attributes = struct
  module Primary = struct
    module Authorization_type = struct
      let t_of_yojson = function
        | `String "abac" -> Ok `Abac
        | `String "rbac" -> Ok `Rbac
        | `String "unknown_authorization" -> Ok `Unknown_authorization
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Abac -> `String "abac"
        | `Rbac -> `String "rbac"
        | `Unknown_authorization -> `String "unknown_authorization"

      type t =
        ([ `Abac
         | `Rbac
         | `Unknown_authorization
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      api_url : string;
      authorization_type : Authorization_type.t; [@default `Rbac]
      ca_cert : string option; [@default None]
      namespace : string option; [@default None]
      token : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  domain : string option; [@default None]
  enabled : bool; [@default true]
  environment_scope : string; [@default "*"]
  managed : bool; [@default true]
  management_project_id : int option; [@default None]
  name : string;
  namespace_per_environment : bool; [@default true]
  platform_kubernetes_attributes : Platform_kubernetes_attributes.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
