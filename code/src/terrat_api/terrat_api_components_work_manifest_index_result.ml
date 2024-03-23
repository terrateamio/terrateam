type t = {
  paths : Terrat_api_components_work_manifest_index_paths.t;
  success : bool;
  symlinks : Terrat_api_components_work_manifest_index_symlinks.t option; [@default None]
  version : int;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
