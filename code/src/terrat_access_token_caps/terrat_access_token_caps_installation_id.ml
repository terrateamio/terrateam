module Name = struct
  let t_of_yojson = function
    | `String "installation_id" -> Ok `Installation_id
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Installation_id -> `String "installation_id"

  type t = ([ `Installation_id ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  id : string;
  name : Name.t;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
