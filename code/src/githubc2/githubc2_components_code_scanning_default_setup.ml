module Primary = struct
  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "actions" -> Ok "actions"
        | `String "c-cpp" -> Ok "c-cpp"
        | `String "csharp" -> Ok "csharp"
        | `String "go" -> Ok "go"
        | `String "java-kotlin" -> Ok "java-kotlin"
        | `String "javascript-typescript" -> Ok "javascript-typescript"
        | `String "javascript" -> Ok "javascript"
        | `String "python" -> Ok "python"
        | `String "ruby" -> Ok "ruby"
        | `String "typescript" -> Ok "typescript"
        | `String "swift" -> Ok "swift"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Query_suite = struct
    let t_of_yojson = function
      | `String "default" -> Ok "default"
      | `String "extended" -> Ok "extended"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "standard" -> Ok "standard"
      | `String "labeled" -> Ok "labeled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Schedule = struct
    let t_of_yojson = function
      | `String "weekly" -> Ok "weekly"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok "configured"
      | `String "not-configured" -> Ok "not-configured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    languages : Languages.t option; [@default None]
    query_suite : Query_suite.t option; [@default None]
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
    schedule : Schedule.t option; [@default None]
    state : State.t option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
