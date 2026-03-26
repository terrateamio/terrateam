module Status = struct
  let t_of_yojson = function
    | `String "default" -> Ok `Default
    | `String "hidden" -> Ok `Hidden
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Default -> `String "default"
    | `Hidden -> `String "hidden"

  type t =
    ([ `Default
     | `Hidden
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  path : string option; [@default None]
  status : Status.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
