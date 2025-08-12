module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "api" -> Ok "api"
      | `String "read_api" -> Ok "read_api"
      | `String "read_user" -> Ok "read_user"
      | `String "create_runner" -> Ok "create_runner"
      | `String "manage_runner" -> Ok "manage_runner"
      | `String "k8s_proxy" -> Ok "k8s_proxy"
      | `String "self_rotate" -> Ok "self_rotate"
      | `String "read_repository" -> Ok "read_repository"
      | `String "write_repository" -> Ok "write_repository"
      | `String "read_observability" -> Ok "read_observability"
      | `String "write_observability" -> Ok "write_observability"
      | `String "ai_features" -> Ok "ai_features"
      | `String "sudo" -> Ok "sudo"
      | `String "admin_mode" -> Ok "admin_mode"
      | `String "read_service_ping" -> Ok "read_service_ping"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option; [@default None]
  expires_at : string option; [@default None]
  name : string;
  scopes : Scopes.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
