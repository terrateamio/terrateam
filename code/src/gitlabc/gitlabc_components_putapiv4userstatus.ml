module Clear_status_after = struct
  let t_of_yojson = function
    | `String "1_day" -> Ok `V_1_day
    | `String "30_days" -> Ok `V_30_days
    | `String "30_minutes" -> Ok `V_30_minutes
    | `String "3_days" -> Ok `V_3_days
    | `String "3_hours" -> Ok `V_3_hours
    | `String "7_days" -> Ok `V_7_days
    | `String "8_hours" -> Ok `V_8_hours
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `V_1_day -> `String "1_day"
    | `V_30_days -> `String "30_days"
    | `V_30_minutes -> `String "30_minutes"
    | `V_3_days -> `String "3_days"
    | `V_3_hours -> `String "3_hours"
    | `V_7_days -> `String "7_days"
    | `V_8_hours -> `String "8_hours"

  type t =
    ([ `V_1_day
     | `V_30_days
     | `V_30_minutes
     | `V_3_days
     | `V_3_hours
     | `V_7_days
     | `V_8_hours
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  availability : string option; [@default None]
  clear_status_after : Clear_status_after.t option; [@default None]
  emoji : string option; [@default None]
  message : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
