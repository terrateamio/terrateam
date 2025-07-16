type t = {
  created_at : string option; [@default None]
  disk_path : string option; [@default None]
  project_id : int option; [@default None]
  repository_storage : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
