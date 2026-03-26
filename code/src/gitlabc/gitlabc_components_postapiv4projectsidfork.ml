module Visibility = struct
  let t_of_yojson = function
    | `String "internal" -> Ok `Internal
    | `String "private" -> Ok `Private
    | `String "public" -> Ok `Public
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Internal -> `String "internal"
    | `Private -> `String "private"
    | `Public -> `String "public"

  type t =
    ([ `Internal
     | `Private
     | `Public
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  branches : string option; [@default None]
  description : string option; [@default None]
  mr_default_target_self : bool option; [@default None]
  name : string option; [@default None]
  namespace : string option; [@default None]
  namespace_id : int option; [@default None]
  namespace_path : string option; [@default None]
  path : string option; [@default None]
  visibility : Visibility.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
