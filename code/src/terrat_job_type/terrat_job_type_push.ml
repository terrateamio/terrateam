module Type_ = struct
  let t_of_yojson = function
    | `String "push" -> Ok `Push
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Push -> `String "push"

  type t = ([ `Push ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { type_ : Type_.t [@key "type"] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
