module Provider = struct
  let t_of_yojson = function
    | `String "aws" -> Ok `Aws
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Aws -> `String "aws"

  type t = ([ `Aws ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "oidc" -> Ok `Oidc
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Oidc -> `String "oidc"

  type t = ([ `Oidc ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  assume_role_arn : string option; [@default None]
  assume_role_enabled : bool; [@default true]
  audience : string option; [@default None]
  duration : int; [@default 3600]
  provider : Provider.t option; [@default None]
  region : string; [@default "us-east-1"]
  role_arn : string;
  session_name : string; [@default "terrateam"]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
