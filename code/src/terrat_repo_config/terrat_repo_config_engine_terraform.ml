module Name = struct
  let t_of_yojson = function
    | `String "terraform" -> Ok "terraform"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  name : Name.t;
  override_tf_cmd : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
