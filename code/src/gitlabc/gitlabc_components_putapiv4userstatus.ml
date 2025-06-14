module Primary = struct
  module Clear_status_after = struct
    let t_of_yojson = function
      | `String "30_minutes" -> Ok "30_minutes"
      | `String "3_hours" -> Ok "3_hours"
      | `String "8_hours" -> Ok "8_hours"
      | `String "1_day" -> Ok "1_day"
      | `String "3_days" -> Ok "3_days"
      | `String "7_days" -> Ok "7_days"
      | `String "30_days" -> Ok "30_days"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    availability : string option; [@default None]
    clear_status_after : Clear_status_after.t option; [@default None]
    emoji : string option; [@default None]
    message : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
