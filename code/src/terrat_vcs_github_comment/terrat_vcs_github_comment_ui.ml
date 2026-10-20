module Ui = struct
  module Api = Terrat_vcs_api_github

  let base_url ~brand config account =
    Printf.sprintf
      "%s/i/%d"
      (Uri.to_string (Terrat_config.web_base_url (Api.Config.config config) brand))
      (Api.Account.id account)

  (* For pull request runs, link to the PR-level runs page which lists every run
     for the pull request.  For non-pull-request targets (e.g. drift), which have
     no pull request to aggregate, fall back to the single work manifest's run. *)
  let work_manifest_url ~brand config account pull_request_ref work_manifest =
    let module Wm = Terrat_work_manifest3 in
    let url =
      match pull_request_ref with
      | Some (repo, pull_number) ->
          Printf.sprintf
            "%s/runs/pr/%s/%d"
            (base_url ~brand config account)
            (Uri.pct_encode ~component:`Path (Api.Repo.name repo))
            pull_number
      | None ->
          Printf.sprintf
            "%s/runs/%s"
            (base_url ~brand config account)
            (Uuidm.to_string work_manifest.Wm.id)
    in
    Some (Uri.of_string url)

  (* Link to a specific work manifest's run detail. *)
  let run_url ~brand config account work_manifest_id =
    Some
      (Uri.of_string
         (Printf.sprintf
            "%s/runs/%s"
            (base_url ~brand config account)
            (Uuidm.to_string work_manifest_id)))
end
