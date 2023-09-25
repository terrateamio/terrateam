module Primary = struct
  module Ruleset_source_type = struct
    let t_of_yojson = function
      | `String "Repository" -> Ok "Repository"
      | `String "Organization" -> Ok "Organization"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
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
