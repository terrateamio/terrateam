type t = {
  outputs : Terrat_api_components_workflow_outputs.t;
  path : string;
  success : bool;
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
