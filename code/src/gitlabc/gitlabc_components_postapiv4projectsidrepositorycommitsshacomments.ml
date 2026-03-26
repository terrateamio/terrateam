module Line_type = struct
  let t_of_yojson = function
    | `String "new" -> Ok `New
    | `String "old" -> Ok `Old
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `New -> `String "new"
    | `Old -> `String "old"

  type t =
    ([ `New
     | `Old
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  line : int;
  line_type : Line_type.t; [@default `New]
  note : string;
  path : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
