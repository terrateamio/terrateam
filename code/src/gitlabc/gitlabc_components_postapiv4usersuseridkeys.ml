module Usage_type = struct
  let t_of_yojson = function
    | `String "auth" -> Ok `Auth
    | `String "auth_and_signing" -> Ok `Auth_and_signing
    | `String "signing" -> Ok `Signing
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Auth -> `String "auth"
    | `Auth_and_signing -> `String "auth_and_signing"
    | `Signing -> `String "signing"

  type t =
    ([ `Auth
     | `Auth_and_signing
     | `Signing
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  expires_at : string option; [@default None]
  key : string;
  title : string;
  usage_type : Usage_type.t; [@default `Auth_and_signing]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
