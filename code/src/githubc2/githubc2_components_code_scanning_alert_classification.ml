let t_of_yojson = function
  | `String "generated" -> Ok `Generated
  | `String "library" -> Ok `Library
  | `String "source" -> Ok `Source
  | `String "test" -> Ok `Test
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Generated -> `String "generated"
  | `Library -> `String "library"
  | `Source -> `String "source"
  | `Test -> `String "test"

type t =
  ([ `Generated | `Library | `Source | `Test ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  option
[@@deriving yojson { strict = false; meta = true }, show, eq]
