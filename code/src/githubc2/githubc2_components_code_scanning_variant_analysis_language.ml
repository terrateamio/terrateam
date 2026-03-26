let t_of_yojson = function
  | `String "cpp" -> Ok `Cpp
  | `String "csharp" -> Ok `Csharp
  | `String "go" -> Ok `Go
  | `String "java" -> Ok `Java
  | `String "javascript" -> Ok `Javascript
  | `String "python" -> Ok `Python
  | `String "ruby" -> Ok `Ruby
  | `String "rust" -> Ok `Rust
  | `String "swift" -> Ok `Swift
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Cpp -> `String "cpp"
  | `Csharp -> `String "csharp"
  | `Go -> `String "go"
  | `Java -> `String "java"
  | `Javascript -> `String "javascript"
  | `Python -> `String "python"
  | `Ruby -> `String "ruby"
  | `Rust -> `String "rust"
  | `Swift -> `String "swift"

type t =
  ([ `Cpp
   | `Csharp
   | `Go
   | `Java
   | `Javascript
   | `Python
   | `Ruby
   | `Rust
   | `Swift
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
