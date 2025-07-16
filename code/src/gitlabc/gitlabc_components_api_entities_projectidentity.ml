type t = {
  created_at : string option; [@default None]
  description : string option; [@default None]
  id : int option; [@default None]
  name : string option; [@default None]
  name_with_namespace : string option; [@default None]
  path : string option; [@default None]
  path_with_namespace : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
