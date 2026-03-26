module Primary = struct
  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "not_set" -> Ok `Not_set
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Not_set -> `String "not_set"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Not_set
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
