module Name = struct
  let t_of_yojson = function
    | `String "pulumi" -> Ok `Pulumi
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Pulumi -> `String "pulumi"

  type t = ([ `Pulumi ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { name : Name.t } [@@deriving yojson { strict = true; meta = true }, make, show, eq]
