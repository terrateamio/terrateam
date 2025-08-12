type t = {
  use_inherited_settings : bool option; [@default None]
  workload_identity_federation_project_id : string;
  workload_identity_federation_project_number : string;
  workload_identity_pool_id : string;
  workload_identity_pool_provider_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
