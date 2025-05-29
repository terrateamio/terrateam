module Primary = struct
  module Platform_kubernetes_attributes = struct
    module Primary = struct
      module Authorization_type = struct
        let t_of_yojson = function
          | `String "unknown_authorization" -> Ok "unknown_authorization"
          | `String "rbac" -> Ok "rbac"
          | `String "abac" -> Ok "abac"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        api_url : string;
        authorization_type : Authorization_type.t; [@default "rbac"]
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
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
