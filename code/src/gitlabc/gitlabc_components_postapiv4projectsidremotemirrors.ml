module Auth_method = struct
  let t_of_yojson = function
    | `String "password" -> Ok `Password
    | `String "ssh_public_key" -> Ok `Ssh_public_key
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Password -> `String "password"
    | `Ssh_public_key -> `String "ssh_public_key"

  type t =
    ([ `Password
     | `Ssh_public_key
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  auth_method : Auth_method.t option; [@default None]
  enabled : bool option; [@default None]
  keep_divergent_refs : bool option; [@default None]
  mirror_branch_regex : string option; [@default None]
  only_protected_branches : bool option; [@default None]
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
