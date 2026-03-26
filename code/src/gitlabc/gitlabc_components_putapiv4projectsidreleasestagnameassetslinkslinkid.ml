module Link_type = struct
  let t_of_yojson = function
    | `String "image" -> Ok `Image
    | `String "other" -> Ok `Other
    | `String "package" -> Ok `Package
    | `String "runbook" -> Ok `Runbook
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Image -> `String "image"
    | `Other -> `String "other"
    | `Package -> `String "package"
    | `Runbook -> `String "runbook"

  type t =
    ([ `Image
     | `Other
     | `Package
     | `Runbook
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  direct_asset_path : string option; [@default None]
  filepath : string option; [@default None]
  link_type : Link_type.t; [@default `Other]
  name : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
