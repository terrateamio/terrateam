module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Operator = struct
        let t_of_yojson = function
          | `String "contains" -> Ok `Contains
          | `String "ends_with" -> Ok `Ends_with
          | `String "regex" -> Ok `Regex
          | `String "starts_with" -> Ok `Starts_with
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Contains -> `String "contains"
          | `Ends_with -> `String "ends_with"
          | `Regex -> `String "regex"
          | `Starts_with -> `String "starts_with"

        type t =
          ([ `Contains
           | `Ends_with
           | `Regex
           | `Starts_with
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
      | `String "committer_email_pattern" -> Ok `Committer_email_pattern
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Committer_email_pattern -> `String "committer_email_pattern"

    type t = ([ `Committer_email_pattern ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
