module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  let src = Logs.Src.create ("vcs_event_evaluator2." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)

  type job = (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t

  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks = Terrat_vcs_event_evaluator2_tasks.Make (S) (Keys)

  type err = Builder.err

  (* The default set of tasks *)
  let tasks = Tasks.make_tasks @@ Tasks.default_tasks ()

  let wrap_build ~request_id build =
    let open Abb.Future.Infix_monad in
    build
    >>= function
    | Ok v -> Abb.Future.return (Ok (Some v))
    | Error (`Suspend_eval_err _ as err) ->
        Logs.info (fun m -> m "%s : %a" request_id Builder.pp_err err);
        Abb.Future.return (Ok None)
    | Error #err as err -> Abb.Future.return err

  let log_err ~request_id fut =
    let open Abb.Future.Infix_monad in
    Abb.Future.await_bind
      (function
        | `Det (Ok ret) -> Abb.Future.return (Ok ret)
        | `Det (Error (`Suspend_eval_err _) as err) -> Abb.Future.return err
        | `Det (Error (#Builder.err as err)) ->
            Logs.err (fun m -> m "%s : %a" request_id Builder.pp_err err);
            Abb.Future.return (Error err)
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
      let store = Hmap.empty |> Hmap.add Keys.work_manifest_event (Some event) in
      Builder.State.make ~log_id:request_id ~config ~store ~db ()
      >>= fun s ->
      Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
      Bs.build Builder.rebuilder tasks target (Bs.St.create s)
    in
    log_err ~request_id run

  let rec run_next_pending_compute ~request_id ~config ~storage () =
    let module Wm = Terrat_work_manifest3 in
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.tx db ~f:(fun () ->
            S.Db.query_next_pending_work_manifest ~request_id db
            >>= function
            | Some wm -> (
                Logs.info (fun m -> m "%s : RUN_WORK_MANIFEST : id=%a" request_id Uuidm.pp wm.Wm.id);
                S.Job_context.Compute_node.create
                  ~request_id
                  ~id:wm.Wm.id
                  ~capabilities:{ Tjc.Compute_node.Capabilities.flags = []; sha = wm.Wm.branch_ref }
                  db
                >>= fun compute_node ->
                S.Api.create_client ~request_id config wm.Wm.account
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
                    run_work_manifest_event
                      ~request_id
                      ~config
                      ~db
                      (Keys.Work_manifest_event.Fail { work_manifest = wm })
                    >>= fun () -> Abb.Future.return (Ok `Cont))
            | None -> Abb.Future.return (Ok `Done)))
    >>= function
    | `Cont -> run_next_pending_compute ~request_id ~config ~storage ()
    | `Done -> Abb.Future.return (Ok ())

  let run_pull_request_context
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~user
      ~type_
      ~store
      () =
    let open Abb.Future.Infix_monad in
    log_err ~request_id
    @@ Pgsql_pool.with_conn storage ~f:(fun db ->
           Pgsql_io.tx db ~f:(fun () ->
               let open Irm in
               S.Job_context.create_or_get_for_pull_request
                 ~request_id
                 db
                 account
                 repo
                 pull_request_id
               >>= fun context ->
               S.Job_context.Job.create ~request_id db type_ context (Some user)
               >>= fun job ->
               Logs.info (fun m ->
                   m
                     "%s : target=%s : context_id=%a : job_id=%a"
                     request_id
                     (Hmap.Key.info Keys.eval_job)
                     Uuidm.pp
                     context.Tjc.Context.id
                     Uuidm.pp
                     job.Tjc.Job.id);
               let open Abb.Future.Infix_monad in
               let store =
                 store |> Hmap.add Keys.job job |> Hmap.add Keys.context_id context.Tjc.Context.id
               in
               Builder.State.make ~log_id:(Uuidm.to_string job.Tjc.Job.id) ~config ~store ~db ()
               >>= fun s ->
               match context.Tjc.Context.scope with
               | Tjc.Context.Scope.Setup ->
                   let open Irm in
                   Logs.info (fun m ->
                       m
                         "%s : SETUP_CONTEXT : context=%a"
                         (Builder.log_id s)
                         Uuidm.pp
                         context.Tjc.Context.id);
                   Bs.build
                     Builder.rebuilder
                     tasks
                     Keys.update_context_for_pull_request
                     (Bs.St.create s)
                   >>= fun () ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info Keys.eval_job));
                   wrap_build ~request_id
                   @@ Bs.build Builder.rebuilder tasks Keys.eval_job (Bs.St.create s)
               | _ ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info Keys.eval_job));
                   wrap_build ~request_id
                   @@ Bs.build Builder.rebuilder tasks Keys.eval_job (Bs.St.create s)))
    >>= fun _ -> run_next_pending_compute ~request_id ~config ~storage ()

  let pull_request_open ~request_id ~config ~storage ~account ~repo ~pull_request_id ~user () =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.repo repo
      |> Hmap.add Keys.user (Some user)
      |> Hmap.add Keys.work_manifest_event None
    in
    Abbs_future_combinators.ignore
    @@ Abb.Future.fork
    @@ run_pull_request_context
         ~request_id
         ~config
         ~storage
         ~account
         ~repo
         ~pull_request_id
         ~user
         ~type_:Terrat_job_context.Job.Type_.Autoplan
         ~store
         ()

  let pull_request_job
      ?comment_id
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~user
      type_ =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> (fun m -> CCOption.map_or ~default:m (fun c -> Hmap.add Keys.comment_id c m) comment_id)
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.repo repo
      |> Hmap.add Keys.user (Some user)
      |> Hmap.add Keys.work_manifest_event None
    in
    Abbs_future_combinators.ignore
    @@ Abb.Future.fork
    @@ run_pull_request_context
         ~request_id
         ~config
         ~storage
         ~account
         ~repo
         ~pull_request_id
         ~user
         ~type_
         ~store
         ()

  let compute_node_poll ~request_id ~config ~storage ~compute_node_id offering =
    let open Abb.Future.Infix_monad in
    let run =
      let target = Keys.eval_compute_node_poll in
      let store =
        Hmap.empty
        |> Hmap.add Keys.compute_node_id compute_node_id
        |> Hmap.add Keys.compute_node_offering offering
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Builder.State.make ~log_id:request_id ~config ~store ~db ()
              >>= fun s ->
              Logs.info (fun m -> m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
              Bs.build Builder.rebuilder tasks target (Bs.St.create s)))
    in
    Abbs_future_combinators.protect (fun () -> log_err ~request_id run)
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error _ -> Abb.Future.return (Error `Error)

  let work_manifest_result ~request_id ~config ~storage ~work_manifest_id result =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              let target = Keys.eval_work_manifest_event in
              S.Work_manifest.query ~request_id db work_manifest_id
              >>= function
              | Some work_manifest -> (
                  S.Job_context.Compute_node.query ~request_id ~compute_node_id:work_manifest_id db
                  >>= function
                  | Some compute_node ->
                      let work_manifest_event =
                        Keys.Work_manifest_event.Result { work_manifest; result }
                      in
                      let store =
                        Hmap.empty
                        |> Hmap.add Keys.compute_node compute_node
                        |> Hmap.add Keys.work_manifest_event (Some work_manifest_event)
                      in
                      let open Abb.Future.Infix_monad in
                      Builder.State.make ~log_id:request_id ~config ~store ~db ()
                      >>= fun s ->
                      Logs.info (fun m ->
                          m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info target));
                      wrap_build ~request_id
                      @@ Bs.build Builder.rebuilder tasks target (Bs.St.create s)
                  | None -> raise (Failure "nyi"))
              | None -> raise (Failure "nyi")))
    in
    let open Abb.Future.Infix_monad in
    log_err ~request_id run
    >>= function
    | Ok _ ->
        run_next_pending_compute ~request_id ~config ~storage ()
        >>= fun _ -> Abb.Future.return (Ok ())
    | Error _ ->
        run_next_pending_compute ~request_id ~config ~storage ()
        >>= fun _ -> Abb.Future.return (Error `Error)
end
