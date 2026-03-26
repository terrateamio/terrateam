module Type = struct
  let t_of_yojson = function
    | `String "run" -> Ok `Run
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Run -> `String "run"

  type t = ([ `Run ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  flow : string;
  subflow : string;
  type_ : Type.t option; [@default None] [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
