type t = {
  created_at : string option; [@default None]
  file_md5 : string option; [@default None]
  file_name : string option; [@default None]
  file_sha1 : string option; [@default None]
  file_sha256 : string option; [@default None]
  id : int option; [@default None]
  package_id : int option; [@default None]
  pipelines : Gitlabc_components_api_entities_package_pipeline.t option; [@default None]
  size : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
