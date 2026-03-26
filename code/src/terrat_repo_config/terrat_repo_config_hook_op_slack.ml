module Type = struct
  let t_of_yojson = function
    | `String "slack" -> Ok `Slack
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Slack -> `String "slack"

  type t = ([ `Slack ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  msg : string;
  run_on : Terrat_repo_config_run_on.t option; [@default None]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
