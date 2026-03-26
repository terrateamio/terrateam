module Type_ = struct
  let t_of_yojson = function
    | `String "repo-config" -> Ok `Repo_config
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Repo_config -> `String "repo-config"

  type t = ([ `Repo_config ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { type_ : Type_.t [@key "type"] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
