module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context

module Make (S : Terrat_vcs_provider2.S) = struct
  module Wm = Terrat_work_manifest3
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)

  type existing_wm =
    ( S.Api.Account.t,
      ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t

  let all_wms_completed =
    CCList.for_all (function
      | { Wm.state = Wm.State.(Completed | Aborted); _ } -> true
      | _ -> false)

  let run ~name ~eq ~create ~initiate ~fail ~result s ({ Builder.Bs.Fetcher.fetch } as fetcher) =
    let open Irm in
    let module E = Keys.Work_manifest_event in
    fetch Keys.work_manifest_event
    >>= function
    | Some
        (E.Initiate
           {
             work_manifest = { Wm.id; state = Wm.State.(Queued | Running); _ } as work_manifest;
             run_id;
           }) ->
        Builder.run_db s ~f:(fun db ->
            S.Work_manifest.update_run_id ~request_id:(Builder.log_id s) db id run_id
            >>= fun () ->
            S.Work_manifest.update_state ~request_id:(Builder.log_id s) db id Wm.State.Running)
        >>= fun () ->
        initiate work_manifest s fetcher
        >>= fun response -> Abb.Future.return (Error (`Suspend_eval_err name))
    | Some (E.Initiate _) -> raise (Failure "nyi")
    | Some (E.Fail { work_manifest }) -> (
        fail work_manifest s fetcher
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval_err name)))
    | Some (E.Result { work_manifest; result = wm_result }) -> (
        result work_manifest wm_result s fetcher
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval_err name)))
    | None -> (
        fetch Keys.work_manifests_for_job
        >>= fun wms ->
        match CCList.filter eq wms with
        | [] ->
            create s fetcher
            >>= fun wms ->
            fetch Keys.job
            >>= fun job ->
            Builder.run_db s ~f:(fun db ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun { Wm.id = work_manifest_id; _ } ->
                    S.Job_context.Job.add_work_manifest
                      ~request_id:(Builder.log_id s)
                      db
                      ~job_id:job.Tjc.Job.id
                      ~work_manifest_id
                      ())
                  wms)
            >>= fun () -> Abb.Future.return (Error (`Suspend_eval_err name))
        | wms when all_wms_completed wms -> Abb.Future.return (Ok wms)
        | _ -> Abb.Future.return (Error (`Suspend_eval_err name)))
end
