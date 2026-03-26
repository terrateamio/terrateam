module Type = struct
  let t_of_yojson = function
    | `String "dirspace" -> Ok `Dirspace
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Dirspace -> `String "dirspace"

  type t = ([ `Dirspace ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dir : string;
  type_ : Type.t option; [@default None] [@key "type"]
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
