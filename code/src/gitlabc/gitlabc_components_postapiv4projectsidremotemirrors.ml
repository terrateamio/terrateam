module Auth_method = struct
  let t_of_yojson = function
    | `String "ssh_public_key" -> Ok "ssh_public_key"
    | `String "password" -> Ok "password"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
