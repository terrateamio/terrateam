module Steps = struct
  type t = Terrat_api_components_workflow_step_output.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { steps : Steps.t } [@@deriving yojson { strict = true; meta = true }, show, eq]
