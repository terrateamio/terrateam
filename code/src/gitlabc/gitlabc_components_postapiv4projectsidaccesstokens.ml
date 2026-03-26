module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "ai_features" -> Ok `Ai_features
      | `String "api" -> Ok `Api
      | `String "create_runner" -> Ok `Create_runner
      | `String "k8s_proxy" -> Ok `K8s_proxy
      | `String "manage_runner" -> Ok `Manage_runner
      | `String "read_api" -> Ok `Read_api
      | `String "read_observability" -> Ok `Read_observability
      | `String "read_repository" -> Ok `Read_repository
      | `String "self_rotate" -> Ok `Self_rotate
      | `String "write_observability" -> Ok `Write_observability
      | `String "write_repository" -> Ok `Write_repository
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Ai_features -> `String "ai_features"
      | `Api -> `String "api"
      | `Create_runner -> `String "create_runner"
      | `K8s_proxy -> `String "k8s_proxy"
      | `Manage_runner -> `String "manage_runner"
      | `Read_api -> `String "read_api"
      | `Read_observability -> `String "read_observability"
      | `Read_repository -> `String "read_repository"
      | `Self_rotate -> `String "self_rotate"
      | `Write_observability -> `String "write_observability"
      | `Write_repository -> `String "write_repository"

    type t =
      ([ `Ai_features
       | `Api
       | `Create_runner
       | `K8s_proxy
       | `Manage_runner
       | `Read_api
       | `Read_observability
       | `Read_repository
       | `Self_rotate
       | `Write_observability
       | `Write_repository
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_level : int; [@default 40]
  description : string option; [@default None]
  expires_at : string; [@default "2026-03-05T09:41:42.948Z"]
  name : string;
  scopes : Scopes.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
