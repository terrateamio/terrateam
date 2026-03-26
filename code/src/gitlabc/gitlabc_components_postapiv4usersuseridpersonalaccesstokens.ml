module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "admin_mode" -> Ok `Admin_mode
      | `String "ai_features" -> Ok `Ai_features
      | `String "api" -> Ok `Api
      | `String "create_runner" -> Ok `Create_runner
      | `String "k8s_proxy" -> Ok `K8s_proxy
      | `String "manage_runner" -> Ok `Manage_runner
      | `String "read_api" -> Ok `Read_api
      | `String "read_observability" -> Ok `Read_observability
      | `String "read_repository" -> Ok `Read_repository
      | `String "read_service_ping" -> Ok `Read_service_ping
      | `String "read_user" -> Ok `Read_user
      | `String "self_rotate" -> Ok `Self_rotate
      | `String "sudo" -> Ok `Sudo
      | `String "write_observability" -> Ok `Write_observability
      | `String "write_repository" -> Ok `Write_repository
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Admin_mode -> `String "admin_mode"
      | `Ai_features -> `String "ai_features"
      | `Api -> `String "api"
      | `Create_runner -> `String "create_runner"
      | `K8s_proxy -> `String "k8s_proxy"
      | `Manage_runner -> `String "manage_runner"
      | `Read_api -> `String "read_api"
      | `Read_observability -> `String "read_observability"
      | `Read_repository -> `String "read_repository"
      | `Read_service_ping -> `String "read_service_ping"
      | `Read_user -> `String "read_user"
      | `Self_rotate -> `String "self_rotate"
      | `Sudo -> `String "sudo"
      | `Write_observability -> `String "write_observability"
      | `Write_repository -> `String "write_repository"

    type t =
      ([ `Admin_mode
       | `Ai_features
       | `Api
       | `Create_runner
       | `K8s_proxy
       | `Manage_runner
       | `Read_api
       | `Read_observability
       | `Read_repository
       | `Read_service_ping
       | `Read_user
       | `Self_rotate
       | `Sudo
       | `Write_observability
       | `Write_repository
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
