module Usage_type = struct
  let t_of_yojson = function
    | `String "auth_and_signing" -> Ok "auth_and_signing"
    | `String "auth" -> Ok "auth"
    | `String "signing" -> Ok "signing"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  expires_at : string option; [@default None]
  key : string;
  title : string;
  usage_type : Usage_type.t; [@default "auth_and_signing"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
