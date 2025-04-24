module Primary = struct
  module Runner_type = struct
    let t_of_yojson = function
      | `String "standard" -> Ok "standard"
      | `String "labeled" -> Ok "labeled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
