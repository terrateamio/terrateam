module Provider = struct
  let t_of_yojson = function
    | `String "gcp" -> Ok `Gcp
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Gcp -> `String "gcp"

  type t = ([ `Gcp ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
  access_token_lifetime : int; [@default 3600]
  access_token_subject : string option; [@default None]
  audience : string option; [@default None]
  project_id : string option; [@default None]
  provider : Provider.t;
  service_account : string;
  type_ : Type.t; [@key "type"]
  workload_identity_provider : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
