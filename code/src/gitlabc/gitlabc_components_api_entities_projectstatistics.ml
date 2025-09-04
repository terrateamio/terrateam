type t = {
  commit_count : string option; [@default None]
  container_registry_size : string option; [@default None]
  job_artifacts_size : string option; [@default None]
  lfs_objects_size : string option; [@default None]
  packages_size : string option; [@default None]
  pipeline_artifacts_size : string option; [@default None]
  repository_size : string option; [@default None]
  snippets_size : string option; [@default None]
  storage_size : string option; [@default None]
  uploads_size : string option; [@default None]
  wiki_size : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
