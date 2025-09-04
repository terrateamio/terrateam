module Variable_type = struct
  let t_of_yojson = function
    | `String "env_var" -> Ok "env_var"
    | `String "file" -> Ok "file"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  value : string option; [@default None]
  variable_type : Variable_type.t; [@default "env_var"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
