module Primary = struct
  module Public_code_suggestions = struct
    let t_of_yojson = function
      | `String "allow" -> Ok "allow"
      | `String "block" -> Ok "block"
      | `String "unconfigured" -> Ok "unconfigured"
      | `String "unknown" -> Ok "unknown"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Seat_management_setting = struct
    let t_of_yojson = function
      | `String "assign_all" -> Ok "assign_all"
      | `String "assign_selected" -> Ok "assign_selected"
      | `String "disabled" -> Ok "disabled"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    public_code_suggestions : Public_code_suggestions.t;
    seat_breakdown : Githubc2_components_copilot_seat_breakdown.t;
    seat_management_setting : Seat_management_setting.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
