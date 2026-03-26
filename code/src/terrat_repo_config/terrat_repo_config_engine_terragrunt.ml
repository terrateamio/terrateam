module Name = struct
  let t_of_yojson = function
    | `String "terragrunt" -> Ok `Terragrunt
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Terragrunt -> `String "terragrunt"

  type t = ([ `Terragrunt ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  name : Name.t;
  outputs : Terrat_repo_config_engine_tf_outputs.t option; [@default None]
  override_tf_cmd : string option; [@default None]
  tf_cmd : string option; [@default None]
  tf_version : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
