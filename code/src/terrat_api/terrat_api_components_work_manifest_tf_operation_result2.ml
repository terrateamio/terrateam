module Gates = struct
  type t = Terrat_api_components_gate.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Steps = struct
  type t = Terrat_api_components_workflow_step_output.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  gates : Gates.t option; [@default None]
  steps : Steps.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
