type t =
  | Apply of Terrat_job_type_apply.t
  | Gate_approval of Terrat_job_type_gate_approval.t
  | Index of Terrat_job_type_index.t
  | Plan of Terrat_job_type_plan.t
  | Push of Terrat_job_type_push.t
  | Repo_config of Terrat_job_type_repo_config.t
  | Unlock of Terrat_job_type_unlock.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> Apply v) (Terrat_job_type_apply.of_yojson v));
       (fun v -> map (fun v -> Gate_approval v) (Terrat_job_type_gate_approval.of_yojson v));
       (fun v -> map (fun v -> Index v) (Terrat_job_type_index.of_yojson v));
       (fun v -> map (fun v -> Plan v) (Terrat_job_type_plan.of_yojson v));
       (fun v -> map (fun v -> Push v) (Terrat_job_type_push.of_yojson v));
       (fun v -> map (fun v -> Repo_config v) (Terrat_job_type_repo_config.of_yojson v));
       (fun v -> map (fun v -> Unlock v) (Terrat_job_type_unlock.of_yojson v));
     ])

let to_yojson = function
  | Apply v -> Terrat_job_type_apply.to_yojson v
  | Gate_approval v -> Terrat_job_type_gate_approval.to_yojson v
  | Index v -> Terrat_job_type_index.to_yojson v
  | Plan v -> Terrat_job_type_plan.to_yojson v
  | Push v -> Terrat_job_type_push.to_yojson v
  | Repo_config v -> Terrat_job_type_repo_config.to_yojson v
  | Unlock v -> Terrat_job_type_unlock.to_yojson v
