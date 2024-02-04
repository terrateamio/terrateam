module Overall = struct
  type t = {
    outputs : Terrat_api_components_hook_outputs.t;
    success : bool;
  }
  [@@deriving yojson { strict = true; meta = true }, show, eq]
end

type t = {
  dirspaces : Terrat_api_components_work_manifest_dirspace_results.t;
  overall : Overall.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
