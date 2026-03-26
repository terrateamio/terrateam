module Languages = struct
  module Items = struct
    let t_of_yojson = function
      | `String "actions" -> Ok `Actions
      | `String "c-cpp" -> Ok `C_cpp
      | `String "csharp" -> Ok `Csharp
      | `String "go" -> Ok `Go
      | `String "java-kotlin" -> Ok `Java_kotlin
      | `String "javascript-typescript" -> Ok `Javascript_typescript
      | `String "python" -> Ok `Python
      | `String "ruby" -> Ok `Ruby
      | `String "swift" -> Ok `Swift
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Actions -> `String "actions"
      | `C_cpp -> `String "c-cpp"
      | `Csharp -> `String "csharp"
      | `Go -> `String "go"
      | `Java_kotlin -> `String "java-kotlin"
      | `Javascript_typescript -> `String "javascript-typescript"
      | `Python -> `String "python"
      | `Ruby -> `String "ruby"
      | `Swift -> `String "swift"

    type t =
      ([ `Actions
       | `C_cpp
       | `Csharp
       | `Go
       | `Java_kotlin
       | `Javascript_typescript
       | `Python
       | `Ruby
       | `Swift
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Query_suite = struct
  let t_of_yojson = function
    | `String "default" -> Ok `Default
    | `String "extended" -> Ok `Extended
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Default -> `String "default"
    | `Extended -> `String "extended"

  type t =
    ([ `Default
     | `Extended
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Runner_type = struct
  let t_of_yojson = function
    | `String "labeled" -> Ok `Labeled
    | `String "standard" -> Ok `Standard
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Labeled -> `String "labeled"
    | `Standard -> `String "standard"

  type t =
    ([ `Labeled
     | `Standard
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "configured" -> Ok `Configured
    | `String "not-configured" -> Ok `Not_configured
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Configured -> `String "configured"
    | `Not_configured -> `String "not-configured"

  type t =
    ([ `Configured
     | `Not_configured
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  languages : Languages.t option; [@default None]
  query_suite : Query_suite.t option; [@default None]
  runner_label : string option; [@default None]
  runner_type : Runner_type.t option; [@default None]
  state : State.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
