let plan_threshold = 50
let apply_threshold = 50

let impacted_dirspaces layers =
  layers |> CCList.concat |> Terrat_data.Dirspace_set.of_list |> Terrat_data.Dirspace_set.cardinal

let enabled ~notifications ~impacted_dirspaces ~run =
  Terrat_base_repo_config_v1.Notifications.dirspace_status_checks_enabled notifications ~run
  &&
  match run with
  | `Plan -> impacted_dirspaces <= plan_threshold
  | `Apply -> impacted_dirspaces <= apply_threshold
  | `Other -> true
