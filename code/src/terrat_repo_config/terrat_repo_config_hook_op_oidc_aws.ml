module Provider = struct
  let t_of_yojson = function
    | `String "aws" -> Ok "aws"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "oidc" -> Ok "oidc"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
