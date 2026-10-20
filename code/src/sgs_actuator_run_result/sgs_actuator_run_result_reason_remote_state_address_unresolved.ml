module Kind = struct
  let t_of_yojson = function
    | `String "remote_state_address_unresolved" -> Ok `Remote_state_address_unresolved
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Remote_state_address_unresolved -> `String "remote_state_address_unresolved"

  type t = ([ `Remote_state_address_unresolved ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  block : string;
  detail : string;
  kind : Kind.t;
  variable : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
