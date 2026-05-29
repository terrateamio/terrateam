type t =
  | Hook_op_run_format_str of Terrat_repo_config_hook_op_run_format_str.t
  | Hook_op_run_format_obj of Terrat_repo_config_hook_op_run_format_obj.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Hook_op_run_format_str v)
           (Terrat_repo_config_hook_op_run_format_str.of_yojson v));
       (fun v ->
         map
           (fun v -> Hook_op_run_format_obj v)
           (Terrat_repo_config_hook_op_run_format_obj.of_yojson v));
     ])

let to_yojson = function
  | Hook_op_run_format_str v -> Terrat_repo_config_hook_op_run_format_str.to_yojson v
  | Hook_op_run_format_obj v -> Terrat_repo_config_hook_op_run_format_obj.to_yojson v
