let t_of_yojson = function
  | `String "one_day" -> Ok "one_day"
  | `String "three_days" -> Ok "three_days"
  | `String "one_week" -> Ok "one_week"
  | `String "one_month" -> Ok "one_month"
  | `String "six_months" -> Ok "six_months"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) [@@deriving yojson { strict = false; meta = true }, show]
