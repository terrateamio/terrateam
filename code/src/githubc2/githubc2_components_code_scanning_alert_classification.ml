let t_of_yojson = function
  | `String "source" -> Ok "source"
  | `String "generated" -> Ok "generated"
  | `String "test" -> Ok "test"
  | `String "library" -> Ok "library"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show]
