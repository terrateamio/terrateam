let t_of_yojson = function
  | `String "actions" -> Ok `Actions
  | `String "composer" -> Ok `Composer
  | `String "erlang" -> Ok `Erlang
  | `String "go" -> Ok `Go
  | `String "maven" -> Ok `Maven
  | `String "npm" -> Ok `Npm
  | `String "nuget" -> Ok `Nuget
  | `String "other" -> Ok `Other
  | `String "pip" -> Ok `Pip
  | `String "pub" -> Ok `Pub
  | `String "rubygems" -> Ok `Rubygems
  | `String "rust" -> Ok `Rust
  | `String "swift" -> Ok `Swift
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Actions -> `String "actions"
  | `Composer -> `String "composer"
  | `Erlang -> `String "erlang"
  | `Go -> `String "go"
  | `Maven -> `String "maven"
  | `Npm -> `String "npm"
  | `Nuget -> `String "nuget"
  | `Other -> `String "other"
  | `Pip -> `String "pip"
  | `Pub -> `String "pub"
  | `Rubygems -> `String "rubygems"
  | `Rust -> `String "rust"
  | `Swift -> `String "swift"

type t =
  ([ `Actions
   | `Composer
   | `Erlang
   | `Go
   | `Maven
   | `Npm
   | `Nuget
   | `Other
   | `Pip
   | `Pub
   | `Rubygems
   | `Rust
   | `Swift
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
