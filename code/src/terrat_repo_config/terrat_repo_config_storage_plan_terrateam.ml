module Method = struct
  let t_of_yojson = function
    | `String "terrateam" -> Ok `Terrateam
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Terrateam -> `String "terrateam"

  type t = ([ `Terrateam ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { method_ : Method.t [@key "method"] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
