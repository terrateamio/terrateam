module Status = struct
  let t_of_yojson = function
    | `String "default" -> Ok "default"
    | `String "hidden" -> Ok "hidden"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  file : string;
  path : string option; [@default None]
  status : Status.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
