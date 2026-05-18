module Provider = struct
  let t_of_yojson = function
    | `String "azure" -> Ok `Azure
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Azure -> `String "azure"

  type t = ([ `Azure ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
  audience : string option; [@default None]
  client_id : string;
  provider : Provider.t;
  subscription_id : string option; [@default None]
  tenant_id : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
