module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Operator = struct
        let t_of_yojson = function
          | `String "starts_with" -> Ok "starts_with"
          | `String "ends_with" -> Ok "ends_with"
          | `String "contains" -> Ok "contains"
          | `String "regex" -> Ok "regex"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        name : string option; [@default None]
        negate : bool option; [@default None]
        operator : Operator.t;
        pattern : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "branch_name_pattern" -> Ok "branch_name_pattern"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
