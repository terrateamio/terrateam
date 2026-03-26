let t_of_yojson = function
  | `String "one_day" -> Ok `One_day
  | `String "one_month" -> Ok `One_month
  | `String "one_week" -> Ok `One_week
  | `String "six_months" -> Ok `Six_months
  | `String "three_days" -> Ok `Three_days
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `One_day -> `String "one_day"
  | `One_month -> `String "one_month"
  | `One_week -> `String "one_week"
  | `Six_months -> `String "six_months"
  | `Three_days -> `String "three_days"

type t =
  ([ `One_day
   | `One_month
   | `One_week
   | `Six_months
   | `Three_days
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
