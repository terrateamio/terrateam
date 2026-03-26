module Variable_type = struct
  let t_of_yojson = function
    | `String "env_var" -> Ok `Env_var
    | `String "file" -> Ok `File
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Env_var -> `String "env_var"
    | `File -> `String "file"

  type t =
    ([ `Env_var
     | `File
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option; [@default None]
  environment_scope : string option; [@default None]
  key : string;
  masked : string option; [@default None]
  masked_and_hidden : string option; [@default None]
  protected : string option; [@default None]
  raw : string option; [@default None]
  value : string;
  variable_type : Variable_type.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
