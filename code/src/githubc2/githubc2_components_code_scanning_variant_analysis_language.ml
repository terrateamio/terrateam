let t_of_yojson = function
  | `String "cpp" -> Ok "cpp"
  | `String "csharp" -> Ok "csharp"
  | `String "go" -> Ok "go"
  | `String "java" -> Ok "java"
  | `String "javascript" -> Ok "javascript"
  | `String "python" -> Ok "python"
  | `String "ruby" -> Ok "ruby"
  | `String "rust" -> Ok "rust"
  | `String "swift" -> Ok "swift"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
