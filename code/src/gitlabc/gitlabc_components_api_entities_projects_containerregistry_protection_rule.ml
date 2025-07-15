type t = {
  id : int option; [@default None]
  minimum_access_level_for_delete : string option; [@default None]
  minimum_access_level_for_push : string option; [@default None]
  project_id : int option; [@default None]
  repository_path_pattern : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
