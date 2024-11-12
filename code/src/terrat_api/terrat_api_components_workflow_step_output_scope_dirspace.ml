module Type = struct
  let t_of_yojson = function
    | `String "dirspace" -> Ok "dirspace"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dir : string;
  type_ : Type.t option; [@default None] [@key "type"]
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
