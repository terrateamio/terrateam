module Name = struct
  let t_of_yojson = function
    | `String "fly" -> Ok "fly"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  config_file : string;
  name : Name.t;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
