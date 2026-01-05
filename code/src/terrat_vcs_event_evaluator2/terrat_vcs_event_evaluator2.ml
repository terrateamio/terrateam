module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  let src = Logs.Src.create ("vcs_event_evaluator2." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks = Terrat_vcs_event_evaluator2_tasks.Make (S) (Keys)
  module Tasks_pr = Terrat_vcs_event_evaluator2_tasks_pr.Make (S) (Keys)
  module Tasks_branch = Terrat_vcs_event_evaluator2_tasks_branch.Make (S) (Keys)

  type err = Builder.err

  module Pull_request_event = Keys.Pull_request_event

  (* The default set of tasks *)
  let tasks = Tasks.default_tasks ()

  (* Because it's just simpler to work with, we have builds return a [result],
     that way we already have a monad that can short circuit when we do not want
     to continue.  But not all [Error] branches are actually errors. But if we
     return [Error] in a [tx], it gets rolledback.  So this function turns those
     [Error] branches tat are not actually errors into [Ok] branches. *)
  let tx_safe ~request_id build =
    let open Abb.Future.Infix_monad in
    build
    >>= function
    | Ok v -> Abb.Future.return (Ok (`Ok v))
    | Error (`Suspend_eval _ as err) ->
        Logs.info (fun m -> m "%s : %a" request_id Builder.pp_err err);
        Abb.Future.return (Ok err)
    | Error (`Noop as err) ->
        (* A Noop isn't an error, it just means tehre is nothing to do *)
        Logs.info (fun m -> m "%s : %a" request_id Builder.pp_err err);
        Abb.Future.return (Ok `Noop)
    | Error #err as err -> Abb.Future.return err

  let log_err ~request_id fut =
    Abb.Future.await_bind
      (function
        | `Det (Ok ret) -> Abb.Future.return (Ok ret)
        | `Det (Error (`Suspend_eval _) as err) -> Abb.Future.return err
        | `Det (Error (#Builder.err as err)) ->
            Logs.err (fun m -> m "%s : %a" request_id Builder.pp_err err);
            Abb.Future.return (Error err)
        | `Exn (Buildsys.Error.Fetch_cycle_exn exn, bt_opt) ->
            Logs.err (fun m -> m "%s : %a" request_id Buildsys.Error.pp exn);
            CCOption.iter
              (fun bt ->
                Logs.err (fun m ->
                    m "%s : BACKTRACE: %s" request_id (Printexc.raw_backtrace_to_string bt)))
              bt_opt;
            Abb.Future.return (Error `Error)
        | `Exn (exn, bt_opt) ->
            Logs.err (fun m -> m "%s : %s" request_id (Printexc.to_string exn));
            CCOption.iter
              (fun bt ->
                Logs.err (fun m ->
                    m "%s : BACKTRACE: %s" request_id (Printexc.raw_backtrace_to_string bt)))
              bt_opt;
            Abb.Future.return (Error `Error)
        | `Aborted ->
            Logs.err (fun m -> m "%s : ABORTED" request_id);
            Abb.Future.return (Error `Error))
      fut

  let run_work_manifest_event ~request_id ~config ~db event =
    let run =
      let open Abb.Future.Infix_monad in
      let target = Keys.eval_work_manifest_event in
      let store = Hmap.empty |> Keys.Key.add Keys.work_manifest_event (Some event) in
      Builder.State.make ~log_id:request_id ~config ~store ~db ~tasks ()
      >>= fun s ->
      Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
      Builder.eval s target
    in
    log_err ~request_id run

  let rec run_next_pending_compute ~request_id ~config ~storage () =
    let module Wm = Terrat_work_manifest3 in
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_time_it.run
      (fun t -> Logs.info (fun m -> m "%s : RUN_WORK_MANIFEST : time=%f" request_id t))
      (fun () ->
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.tx db ~f:(fun () ->
                S.Db.query_next_pending_work_manifest ~request_id db
                >>= function
                | Some wm -> (
                    Logs.info (fun m ->
                        m "%s : RUN_WORK_MANIFEST : id=%a" request_id Uuidm.pp wm.Wm.id);
                    S.Job_context.Compute_node.create
                      ~request_id
                      ~id:wm.Wm.id
                      ~capabilities:
                        { Tjc.Compute_node.Capabilities.flags = []; sha = wm.Wm.branch_ref }
                      db
                    >>= fun compute_node ->
                    S.Api.create_client ~request_id config wm.Wm.account db
                    >>= fun client ->
                    let open Abb.Future.Infix_monad in
                    S.Work_manifest.run ~request_id config client wm
                    >>= function
                    | Ok () ->
                        let open Abbs_future_combinators.Infix_result_monad in
                        S.Work_manifest.update_state ~request_id db wm.Wm.id Wm.State.Running
                        >>= fun () -> Abb.Future.return (Ok `Cont)
                    | Error err ->
                        let open Abbs_future_combinators.Infix_result_monad in
                        S.Work_manifest.update_state ~request_id db wm.Wm.id Wm.State.Aborted
                        >>= fun () ->
                        S.Job_context.Compute_node.update_state
                          ~request_id
                          ~compute_node_id:compute_node.Tjc.Compute_node.id
                          db
                          Tjc.Compute_node.State.Terminated
                        >>= fun () ->
                        let open Abb.Future.Infix_monad in
                        run_work_manifest_event
                          ~request_id
                          ~config
                          ~db
                          (Keys.Work_manifest_event.Fail { work_manifest = wm; error = err })
                        >>= fun _ -> Abb.Future.return (Ok `Cont))
                | None -> Abb.Future.return (Ok `Done))))
    >>= function
    | `Cont -> run_next_pending_compute ~request_id ~config ~storage ()
    | `Done -> Abb.Future.return (Ok ())

  let run_pull_request_event
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~user
      ~event
      ~store
      () =
    Abbs_future_combinators.with_finally
      (fun () ->
        let open Irm in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            let store =
              store
              |> Keys.Key.add Keys.account account
              |> Keys.Key.add Keys.user (Some user)
              |> Keys.Key.add Keys.repo repo
              |> Keys.Key.add Keys.pull_request_id pull_request_id
              |> Keys.Key.add Keys.pull_request_event event
            in
            let open Abb.Future.Infix_monad in
            Builder.State.make
              ~log_id:request_id
              ~config
              ~store
              ~db
              ~tasks:(Tasks_pr.tasks tasks)
              ()
            >>= fun s ->
            let open Irm in
            log_err ~request_id @@ Builder.eval s Keys.update_context_branch_hashes
            >>= fun () ->
            Pgsql_io.tx db ~f:(fun () ->
                let open Abb.Future.Infix_monad in
                Builder.State.make
                  ~log_id:request_id
                  ~config
                  ~store
                  ~db
                  ~tasks:(Tasks_pr.tasks tasks)
                  ()
                >>= fun s ->
                let open Irm in
                log_err ~request_id @@ Builder.eval s Keys.get_context_for_pull_request
                >>= fun context ->
                let s =
                  s
                  |> Builder.State.orig_store
                  |> Keys.Key.add Keys.context context
                  |> CCFun.flip Builder.State.set_orig_store s
                in
                Abb.Future.return (Ok s))
            >>= fun s ->
            Pgsql_io.tx db ~f:(fun () ->
                Logs.info (fun m ->
                    m
                      "%s : target=%s"
                      (Builder.log_id s)
                      (Hmap.Key.info Keys.eval_pull_request_event));
                log_err ~request_id @@ Builder.eval s Keys.eval_pull_request_event)
            >>= fun job ->
            let open Abb.Future.Infix_monad in
            Pgsql_io.tx db ~f:(fun () ->
                let s' =
                  s
                  |> Builder.State.orig_store
                  |> Keys.Key.add Keys.job job
                  |> CCFun.flip Builder.State.set_orig_store s
                  |> Builder.State.set_log_id (Builder.mk_log_id ~request_id job.Tjc.Job.id)
                in
                log_err ~request_id @@ tx_safe ~request_id @@ Builder.eval s' Keys.iter_job)
            >>= function
            | Ok (`Ok _) ->
                Pgsql_io.tx db ~f:(fun () ->
                    let s' =
                      s
                      |> Builder.State.orig_store
                      |> Keys.Key.add Keys.job job
                      |> CCFun.flip Builder.State.set_orig_store s
                      |> Builder.State.set_log_id (Builder.mk_log_id ~request_id job.Tjc.Job.id)
                      |> Builder.State.set_tasks (Tasks_pr.tasks @@ Builder.State.tasks s)
                    in
                    log_err ~request_id
                    @@ tx_safe ~request_id
                    @@ Builder.eval s' Keys.run_next_layer)
            | Ok (`Suspend_eval _) -> (
                Pgsql_io.tx db ~f:(fun () ->
                    let s' =
                      s
                      |> Builder.State.orig_store
                      |> Keys.Key.add Keys.job job
                      |> CCFun.flip Builder.State.set_orig_store s
                      |> Builder.State.set_log_id (Builder.mk_log_id ~request_id job.Tjc.Job.id)
                    in
                    log_err ~request_id
                    @@ tx_safe ~request_id
                    @@ Builder.eval s' Keys.maybe_complete_job)
                >>= function
                | Ok (`Ok ()) ->
                    Pgsql_io.tx db ~f:(fun () ->
                        let s' =
                          s
                          |> Builder.State.orig_store
                          |> Keys.Key.add Keys.job job
                          |> CCFun.flip Builder.State.set_orig_store s
                          |> Builder.State.set_log_id (Builder.mk_log_id ~request_id job.Tjc.Job.id)
                          |> Builder.State.set_tasks (Tasks_pr.tasks @@ Builder.State.tasks s)
                        in
                        log_err ~request_id
                        @@ tx_safe ~request_id
                        @@ Builder.eval s' Keys.run_next_layer)
                | (Ok (`Suspend_eval _ | `Noop) | Error _) as r -> Abb.Future.return r)
            | Ok `Noop -> Abb.Future.return (Ok `Noop)
            | Error err ->
                let open Irm in
                Logs.info (fun m ->
                    m
                      "%s : JOB : FAILED : job_id= %a : %a"
                      request_id
                      Uuidm.pp
                      job.Tjc.Job.id
                      Builder.pp_err
                      err);
                Builder.run_db s ~f:(fun db ->
                    S.Job_context.Job.update_state
                      ~request_id
                      ~job_id:job.Tjc.Job.id
                      db
                      Tjc.Job.State.Failed)
                >>= fun () -> Abb.Future.return (Ok `Noop)))
      ~finally:(fun () ->
        Abbs_future_combinators.ignore
        @@ Abb.Future.fork
        @@ run_next_pending_compute ~request_id ~config ~storage ())

  let pull_request_event ~request_id ~config ~storage ~account ~repo ~pull_request_id ~user event =
    let store =
      Hmap.empty
      |> Keys.Key.add Keys.account account
      |> Keys.Key.add Keys.pull_request_id pull_request_id
      |> Keys.Key.add Keys.repo repo
      |> Keys.Key.add Keys.user (Some user)
      |> Keys.Key.add Keys.work_manifest_event None
    in
    Abbs_future_combinators.ignore
    @@ Abb.Future.fork
    @@ run_pull_request_event
         ~request_id
         ~config
         ~storage
         ~account
         ~repo
         ~pull_request_id
         ~user
         ~event
         ~store
         ()

  let work_manifest_job_failed ~request_id ~config ~storage ~account ~repo ~run_id () =
    let open Abb.Future.Infix_monad in
    let run =
      let target = Keys.eval_work_manifest_failure in
      let store =
        Hmap.empty
        |> Keys.Key.add Keys.account account
        |> Keys.Key.add Keys.repo repo
        |> Keys.Key.add Keys.run_id run_id
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Builder.State.make ~log_id:request_id ~config ~store ~db ~tasks ()
              >>= fun s ->
              Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
              tx_safe ~request_id @@ Builder.eval s target))
    in
    Abbs_future_combinators.ignore @@ log_err ~request_id run

  let compute_node_poll ~request_id ~config ~storage ~compute_node_id offering =
    let open Abb.Future.Infix_monad in
    let run =
      let target = Keys.eval_compute_node_poll in
      let store =
        Hmap.empty
        |> Keys.Key.add Keys.compute_node_id compute_node_id
        |> Keys.Key.add Keys.compute_node_offering offering
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Builder.State.make ~log_id:request_id ~config ~store ~db ~tasks ()
              >>= fun s ->
              Logs.info (fun m ->
                  m
                    "%s : COMPUTE_NODE_POLL : compute_node_id = %a"
                    (Builder.log_id s)
                    Uuidm.pp
                    compute_node_id);
              tx_safe ~request_id @@ Builder.eval s target))
    in
    Abbs_future_combinators.protect (fun () -> log_err ~request_id run)
    >>= function
    | Ok (`Ok r) -> Abb.Future.return (Ok r)
    | Ok (`Suspend_eval _) | Ok `Noop | Error _ -> Abb.Future.return (Error `Error)

  let work_manifest_result ~request_id ~config ~storage ~work_manifest_id result =
    let query_work_manifest db =
      let open Irm in
      S.Work_manifest.query ~request_id db work_manifest_id
      >>= function
      | Some work_manifest -> Abb.Future.return (Ok work_manifest)
      | None -> Abb.Future.return (Error `Error)
    in
    let query_compute_node db =
      let open Irm in
      S.Job_context.Compute_node.query ~request_id ~compute_node_id:work_manifest_id db
      >>= function
      | Some compute_node -> Abb.Future.return (Ok compute_node)
      | None -> Abb.Future.return (Error `Error)
    in
    let query_job db =
      S.Job_context.Job.query_by_work_manifest_id ~request_id ~work_manifest_id db ()
    in
    let add_work_manifest_keys work_manifest store =
      let module Wm = Terrat_work_manifest3 in
      let { Wm.id; account; target; _ } = work_manifest in
      match target with
      | Terrat_vcs_provider2.Target.Pr pr ->
          store
          |> Keys.Key.add Keys.account account
          |> Keys.Key.add Keys.pull_request_id (S.Api.Pull_request.id pr)
          |> Keys.Key.add Keys.repo (S.Api.Pull_request.repo pr)
      | Terrat_vcs_provider2.Target.Drift { repo; _ } ->
          store |> Keys.Key.add Keys.account account |> Keys.Key.add Keys.repo repo
    in
    let run =
      let open Abb.Future.Infix_monad in
      Logs.info (fun m ->
          m "%s : WORK_MANIFEST_RESULT : work_manifest_id= %a" request_id Uuidm.pp work_manifest_id);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              let open Irm in
              query_work_manifest db
              >>= fun work_manifest ->
              query_compute_node db
              >>= fun compute_node ->
              query_job db
              >>= function
              | Some job ->
                  let work_manifest_event =
                    Keys.Work_manifest_event.Result { work_manifest; result }
                  in
                  let store =
                    Hmap.empty
                    |> Keys.Key.add Keys.compute_node compute_node
                    |> Keys.Key.add Keys.work_manifest_event (Some work_manifest_event)
                  in
                  let open Abb.Future.Infix_monad in
                  Builder.State.make ~log_id:request_id ~config ~store ~db ~tasks ()
                  >>= fun s ->
                  let open Irm in
                  let target = Keys.eval_work_manifest_event in
                  Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
                  tx_safe ~request_id @@ Builder.eval s target
                  >>= fun r -> Abb.Future.return (Ok (s, work_manifest, job, r))
              | None ->
                  Logs.info (fun m ->
                      m
                        "%s : JOB_MISSING_FOR_WORK_MANIFEST : work_manifest_id= %a"
                        request_id
                        Uuidm.pp
                        work_manifest_id);
                  Abb.Future.return (Error `Error))
          >>= function
          | Ok (s, work_manifest, job, `Ok _) ->
              Pgsql_io.tx db ~f:(fun () ->
                  let { Tjc.Job.context = { Tjc.Context.scope; _ }; _ } = job in
                  let s' =
                    s
                    |> Builder.State.orig_store
                    |> Keys.Key.add Keys.job job
                    |> add_work_manifest_keys work_manifest
                    |> CCFun.flip Builder.State.set_orig_store s
                    |> Builder.State.set_tasks
                         (match scope with
                         | Tjc.Context.Scope.Pull_request _ ->
                             Tasks_pr.tasks @@ Builder.State.tasks s
                         | Tjc.Context.Scope.Branch _ -> Tasks_branch.tasks @@ Builder.State.tasks s)
                  in
                  tx_safe ~request_id @@ Builder.eval s' Keys.run_next_layer)
          | Ok (s, _work_manifest, job, `Suspend_eval _) -> (
              let { Tjc.Job.context = { Tjc.Context.scope; _ }; _ } = job in
              let s' =
                s
                |> Builder.State.set_tasks
                     (match scope with
                     | Tjc.Context.Scope.Pull_request _ -> Tasks_pr.tasks @@ Builder.State.tasks s
                     | Tjc.Context.Scope.Branch _ -> Tasks_branch.tasks @@ Builder.State.tasks s)
              in
              Pgsql_io.tx db ~f:(fun () ->
                  tx_safe ~request_id
                  @@ Builder.eval s' Keys.maybe_complete_job_from_work_manifest_event)
              >>= function
              | Ok (`Ok ()) ->
                  let { Tjc.Job.context = { Tjc.Context.scope; _ }; _ } = job in
                  let s' =
                    s
                    |> Builder.State.orig_store
                    |> Keys.Key.add Keys.job job
                    |> Builder.State.forward_store_value Keys.repo_config_with_provenance s
                    |> Builder.State.forward_store_value Keys.repo_config_raw s
                    |> Builder.State.forward_store_value Keys.repo_config_raw' s
                    |> Builder.State.forward_store_value Keys.pull_request s
                    |> Builder.State.forward_store_value Keys.work_manifests_for_job s
                    |> CCFun.flip Builder.State.set_orig_store s
                    |> Builder.State.set_tasks
                         (match scope with
                         | Tjc.Context.Scope.Pull_request _ ->
                             Tasks_pr.tasks @@ Builder.State.tasks s
                         | Tjc.Context.Scope.Branch _ -> Tasks_branch.tasks @@ Builder.State.tasks s)
                  in
                  Pgsql_io.tx db ~f:(fun () ->
                      tx_safe ~request_id @@ Builder.eval s' Keys.run_next_layer)
              | (Ok (`Suspend_eval _ | `Noop) | Error _) as r -> Abb.Future.return r)
          | Ok (_, _, _, `Noop) -> Abb.Future.return (Ok `Noop)
          | Error #err as err -> Abb.Future.return err)
    in
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.with_finally
      (fun () ->
        log_err ~request_id run
        >>= function
        | Ok _ -> Abb.Future.return (Ok ())
        | Error _ -> Abb.Future.return (Error `Error))
      ~finally:(fun () ->
        Abbs_future_combinators.ignore
        @@ Abb.Future.fork
        @@ run_next_pending_compute ~request_id ~config ~storage ())

  let push ~request_id ~config ~storage ~account ~repo ~branch ~user () =
    let run =
      let open Irm in
      let target = Keys.eval_push_event in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              S.Job_context.create_or_get_for_branch ~request_id db account repo branch
              >>= fun context ->
              S.Job_context.Job.create ~request_id db Tjc.Job.Type_.Push context (Some user))
          >>= fun job ->
          let store =
            Hmap.empty
            |> Keys.Key.add Keys.account account
            |> Keys.Key.add Keys.repo repo
            |> Keys.Key.add Keys.user (Some user)
            |> Keys.Key.add Keys.job job
          in
          let open Abb.Future.Infix_monad in
          Builder.State.make
            ~log_id:request_id
            ~config
            ~store
            ~db
            ~tasks:(Tasks_branch.tasks tasks)
            ()
          >>= fun s ->
          let open Irm in
          Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
          log_err ~request_id @@ Builder.eval s Keys.update_context_branch_hashes
          >>= fun () -> Pgsql_io.tx db ~f:(fun () -> tx_safe ~request_id @@ Builder.eval s target))
    in
    Abbs_future_combinators.with_finally
      (fun () -> Abbs_future_combinators.ignore @@ log_err ~request_id run)
      ~finally:(fun () ->
        Abbs_future_combinators.ignore
        @@ Abb.Future.fork
        @@ run_next_pending_compute ~request_id ~config ~storage ())

  let run_missing_drift_schedules ~config ~storage () =
    let open Abb.Future.Infix_monad in
    let request_id = "RUN_MISSING_DRIFT_SCHEDULES" in
    let run =
      let target = Keys.run_missing_drift_schedules in
      let store = Hmap.empty in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Builder.State.make
                ~log_id:request_id
                ~config
                ~store
                ~db
                ~tasks:(Tasks_branch.tasks tasks)
                ()
              >>= fun s ->
              Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
              tx_safe ~request_id @@ Builder.eval s target))
    in
    Abbs_future_combinators.with_finally
      (fun () -> Abbs_future_combinators.ignore @@ log_err ~request_id run)
      ~finally:(fun () ->
        Abbs_future_combinators.ignore
        @@ Abb.Future.fork
        @@ run_next_pending_compute ~request_id ~config ~storage ())
end
