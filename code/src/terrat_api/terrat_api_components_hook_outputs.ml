module Post = struct
  module Items = struct
    type t = Workflow_output_run of Terrat_api_components_workflow_output_run.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [
          (fun v ->
            map
              (fun v -> Workflow_output_run v)
              (Terrat_api_components_workflow_output_run.of_yojson v));
        ])

    let to_yojson = function
      | Workflow_output_run v -> Terrat_api_components_workflow_output_run.to_yojson v
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Pre = struct
  module Items = struct
    type t =
      | Workflow_output_run of Terrat_api_components_workflow_output_run.t
      | Workflow_output_checkout of Terrat_api_components_workflow_output_checkout.t
      | Workflow_output_cost_estimation of Terrat_api_components_workflow_output_cost_estimation.t
    [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [
          (fun v ->
            map
              (fun v -> Workflow_output_run v)
              (Terrat_api_components_workflow_output_run.of_yojson v));
          (fun v ->
            map
              (fun v -> Workflow_output_checkout v)
              (Terrat_api_components_workflow_output_checkout.of_yojson v));
          (fun v ->
            map
              (fun v -> Workflow_output_cost_estimation v)
              (Terrat_api_components_workflow_output_cost_estimation.of_yojson v));
        ])

    let to_yojson = function
      | Workflow_output_run v -> Terrat_api_components_workflow_output_run.to_yojson v
      | Workflow_output_checkout v -> Terrat_api_components_workflow_output_checkout.to_yojson v
      | Workflow_output_cost_estimation v ->
          Terrat_api_components_workflow_output_cost_estimation.to_yojson v
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  post : Post.t;
  pre : Pre.t;
}
[@@deriving yojson { strict = true; meta = true }, show]
