module Provider = struct
  let t_of_yojson = function
    | `String "gcp" -> Ok "gcp"
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
