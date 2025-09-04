module Link_type = struct
  let t_of_yojson = function
    | `String "other" -> Ok "other"
    | `String "runbook" -> Ok "runbook"
    | `String "image" -> Ok "image"
    | `String "package" -> Ok "package"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  direct_asset_path : string option; [@default None]
  filepath : string option; [@default None]
  link_type : Link_type.t; [@default "other"]
  name : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
