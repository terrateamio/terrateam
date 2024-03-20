module Name = struct
  let t_of_yojson = function
    | `String "terragrunt" -> Ok "terragrunt"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  name : Name.t;
  tf_cmd : string; [@default "terraform"]
  tf_version : string; [@default "latest"]
  version : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
