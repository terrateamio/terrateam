module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Serializer = Abb_service_serializer.Make (Abb.Future)
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  let src = Logs.Src.create "vcs_event_evaluator2"

  module Logs = (val Logs.src_log src : Logs.LOG)

  type context = (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t
  type job = (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t

  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks = Terrat_vcs_event_evaluator2_tasks.Make (S)

  (* State machine for processing a work manifest *)
  module Work_manifest_sm = struct
    module Wm = Terrat_work_manifest3

    (* let create_work_manifest ~create s ({ Bs.Fetcher.fetch } as fetcher) = *)
    (*   let open Irm in *)
    (*   create s fetcher *)
    (*   >>= fun work_manifests -> *)
    (*   fetch Keys.job *)
    (*   >>= fun job -> *)
    (*   run_db s ~f:(fun db -> *)
    (*       Abbs_future_combinators.List_result.iter *)
    (*         ~f:(fun { Wm.id = work_manifest_id; _ } -> *)
    (*           S.Job_context.Job.add_work_manifest *)
    (*             ~request_id:(B.State.log_id s) *)
    (*             db *)
    (*             ~job_id:job.Tjc.Job.id *)
    (*             ~work_manifest_id *)
    (*             ()) *)
    (*         work_manifests) *)
    (*   >>= fun () -> Abb.Future.return (Error (`Suspend_eval_err "create_work_manifest")) *)

    (* let run ~eq ~create ~initiate ~fail ~results s ({ Bs.Fetcher.fetch } as fetcher) = *)
    (*   raise (Failure "nyi") *)
    (* let open Irm in *)
    (* fetch Keys.work_manifest *)
    (* >>= function *)
    (* | None -> create_work_manifest ~create s fetcher *)
    (* | Some ({ Wm.state = Wm.State.Running; _ } as wm) -> raise (Failure "nyi") *)
  end

  let tasks_map = Tasks.add_tasks Hmap.empty

  let tasks =
    {
      Bs.Tasks.get =
        (fun s k -> Abb.Future.return (Ok (Hmap.find (Builder.coerce_to_task k) tasks_map)));
    }

  let rebuilder = { Bs.Rebuilder.run = (fun _s _k v _task _fetcher -> Abb.Future.return (Ok v)) }

  let log_err ~request_id fut =
    let open Abb.Future.Infix_monad in
    Abb.Future.await_bind
      (function
        | `Det (Ok ()) -> Abb.Future.return (Ok ())
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
    Abbs_future_combinators.ignore
    @@ log_err ~request_id
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
               Serializer.create ()
               >>= fun serializer ->
               let db = Serializer.Mutex.create serializer db in
               let store = store |> Hmap.add Keys.job job |> Hmap.add Keys.context context in
               let s =
                 { B.State.log_id = Uuidm.to_string job.Tjc.Job.id; config; store; storage; db }
               in
               match context.Tjc.Context.scope with
               | Tjc.Context.Scope.Setup ->
                   let open Irm in
                   Logs.info (fun m ->
                       m
                         "%s : SETUP_CONTEXT : context=%a"
                         (B.State.log_id s)
                         Uuidm.pp
                         context.Tjc.Context.id);
                   Bs.build rebuilder tasks Keys.update_context_for_pull_request (Bs.St.create s)
                   >>= fun () ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.log_id s) (Hmap.Key.info Keys.eval_job));
                   Bs.build rebuilder tasks Keys.eval_job (Bs.St.create s)
               | _ ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.log_id s) (Hmap.Key.info Keys.eval_job));
                   Bs.build rebuilder tasks Keys.eval_job (Bs.St.create s)))

  let resume_job_from_work_manifest_id ~request_id ~config ~storage ~store ~work_manifest_id () =
    Abbs_future_combinators.ignore
    @@ log_err ~request_id
    @@ Pgsql_pool.with_conn storage ~f:(fun db ->
           Pgsql_io.tx db ~f:(fun () ->
               let open Irm in
               S.Job_context.Job.query_by_work_manifest_id ~request_id db ~work_manifest_id ()
               >>= function
               | None ->
                   Logs.err (fun m -> m "AHHH");
                   raise (Failure "nyi")
               | Some job ->
                   let context = job.Tjc.Job.context in
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
                   Serializer.create ()
                   >>= fun serializer ->
                   let db = Serializer.Mutex.create serializer db in
                   let store = store |> Hmap.add Keys.job job |> Hmap.add Keys.context context in
                   let s =
                     { B.State.log_id = Uuidm.to_string job.Tjc.Job.id; config; store; storage; db }
                   in
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.log_id s) (Hmap.Key.info Keys.eval_job));
                   Bs.build rebuilder tasks Keys.eval_job (Bs.St.create s)))

  let publish_repo_config
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~comment_id
      ~user
      () =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> Hmap.add Keys.comment_id comment_id
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.user user
      |> Hmap.add Keys.repo repo
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
         ~type_:Terrat_job_context.Job.Type_.Repo_config
         ~store
         ()

  let autoplan ~request_id ~config ~storage ~account ~repo ~pull_request_id ~user () =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.user user
      |> Hmap.add Keys.repo repo
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

  let plan
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~comment_id
      ~user
      ~tag_query
      () =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> Hmap.add Keys.comment_id comment_id
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.user user
      |> Hmap.add Keys.repo repo
      |> Hmap.add Keys.tag_query tag_query
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
         ~type_:(Terrat_job_context.Job.Type_.Plan { tag_query })
         ~store
         ()

  let apply
      ~request_id
      ~config
      ~storage
      ~account
      ~repo
      ~pull_request_id
      ~comment_id
      ~user
      ~tag_query
      () =
    let store =
      Hmap.empty
      |> Hmap.add Keys.account account
      |> Hmap.add Keys.comment_id comment_id
      |> Hmap.add Keys.pull_request_id pull_request_id
      |> Hmap.add Keys.user user
      |> Hmap.add Keys.repo repo
      |> Hmap.add Keys.tag_query tag_query
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
         ~type_:(Terrat_job_context.Job.Type_.Apply { tag_query })
         ~store
         ()
end
