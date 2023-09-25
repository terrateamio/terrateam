let t_of_yojson = function
  | `String "rubygems" -> Ok "rubygems"
  | `String "npm" -> Ok "npm"
  | `String "pip" -> Ok "pip"
  | `String "maven" -> Ok "maven"
  | `String "nuget" -> Ok "nuget"
  | `String "composer" -> Ok "composer"
  | `String "go" -> Ok "go"
  | `String "rust" -> Ok "rust"
  | `String "erlang" -> Ok "erlang"
  | `String "actions" -> Ok "actions"
  | `String "pub" -> Ok "pub"
  | `String "other" -> Ok "other"
  | `String "swift" -> Ok "swift"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
