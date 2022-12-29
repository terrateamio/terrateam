module Type = struct
  let t_of_yojson = function
    | `String "slack" -> Ok "slack"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  msg : string;
  run_on : Terrat_repo_config_run_on.t option; [@default None]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
