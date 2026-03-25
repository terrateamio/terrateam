type t =
  | Kind_drift of Terrat_job_type_kind_drift.t
  | Kind_adhoc of Terrat_job_type_kind_adhoc.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> Kind_drift v) (Terrat_job_type_kind_drift.of_yojson v));
       (fun v -> map (fun v -> Kind_adhoc v) (Terrat_job_type_kind_adhoc.of_yojson v));
     ])

let to_yojson = function
  | Kind_drift v -> Terrat_job_type_kind_drift.to_yojson v
  | Kind_adhoc v -> Terrat_job_type_kind_adhoc.to_yojson v
