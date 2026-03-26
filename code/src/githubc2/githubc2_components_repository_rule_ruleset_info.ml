module Primary = struct
  module Ruleset_source_type = struct
    let t_of_yojson = function
      | `String "Organization" -> Ok `Organization
      | `String "Repository" -> Ok `Repository
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Organization -> `String "Organization"
      | `Repository -> `String "Repository"

    type t =
      ([ `Organization
       | `Repository
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ruleset_id : int option; [@default None]
    ruleset_source : string option; [@default None]
    ruleset_source_type : Ruleset_source_type.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
