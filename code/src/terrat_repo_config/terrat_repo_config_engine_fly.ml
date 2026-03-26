module Name = struct
  let t_of_yojson = function
    | `String "fly" -> Ok `Fly
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Fly -> `String "fly"

  type t = ([ `Fly ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  config_file : string;
  name : Name.t;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
