module Name = struct
  let t_of_yojson = function
    | `String "vcs" -> Ok "vcs"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  name : Name.t;
  vcs : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
