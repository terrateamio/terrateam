module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Serializer = Abb_service_serializer.Make (Abb.Future)
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg

module Hmap = Hmap.Make (struct
  type 'a t = string
end)

module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  let src = Logs.Src.create ("vcs_event_evaluator2." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)

  module Key = struct
    type 'a t = 'a Hmap.key
  end

  type repo_config_fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err
  [@@deriving show]

  type err =
    [ `Missing_dep_err of string
    | `Error
    | `Closed
    | repo_config_fetch_err
    | Terrat_change_match3.synthesize_config_err
    | `Require_event_err of string
    | Pgsql_io.err
    | Pgsql_pool.err
    ]
  [@@deriving show]

  type context = (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t
  type job = (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t

  module B = struct
    module Key_repr = struct
      type t = Hmap.Key.t

      let equal = Hmap.Key.equal
    end

    type 'v k = 'v Hmap.key

    let key_repr_of_key = Hmap.Key.hide_type

    module C = struct
      type 'a t = ('a, err) result Abb.Future.t

      let return v = Abb.Future.return (Ok v)
      let ( >>= ) = Irm.( >>= )
    end

    module Notify = struct
      type t = (unit Abb.Future.t * unit Abb.Future.Promise.t) ref

      let create () =
        let p = Abb.Future.Promise.create () in
        let fut = Abb.Future.Promise.future p in
        ref (fut, p)

      let notify t =
        let open Abb.Future.Infix_monad in
        let _, notify = !t in
        let p = Abb.Future.Promise.create () in
        let fut = Abb.Future.Promise.future p in
        t := (fut, p);
        Abb.Future.Promise.set notify () >>= fun () -> Abb.Future.return (Ok ())

      let wait t =
        let open Abb.Future.Infix_monad in
        let wait, _ = !t in
        wait >>= fun () -> Abb.Future.return (Ok ())
    end

    module State = struct
      type t = {
        context : context;
        job : job;
        config : S.Api.Config.t;
        storage : Terrat_storage.t;
        db : Pgsql_io.t Serializer.Mutex.t;
        mutable store : Hmap.t;
      }

      let job_id t = Uuidm.to_string t.job.Tjc.Job.id

      let set_k t k v =
        t.store <- Hmap.add k v t.store;
        Abb.Future.return (Ok ())

      let get_k t k =
        match Hmap.find k t.store with
        | Some v -> Abb.Future.return (Ok v)
        | None -> Abb.Future.return (Error (`Missing_dep_err (Hmap.Key.info k)))

      let get_k_opt t k = Abb.Future.return (Ok (Hmap.find k t.store))
    end
  end

  module Bs = Buildsys.Make (B)

  let run_db s ~f =
    let open Abb.Future.Infix_monad in
    Serializer.Mutex.run s.B.State.db ~f
    >>= function
    | `Ok (Ok v) -> Abb.Future.return (Ok v)
    | `Ok (Error err) -> Abb.Future.return (Error err)
    | `Closed -> Abb.Future.return (Error `Closed)

  external coerce : 'a B.k -> 'a Bs.Task.t B.k = "%identity"

  module Keys = struct
    let account : S.Api.Account.t Hmap.key = Hmap.Key.create "account"
    let account_status : P2.Account_status.t Hmap.key = Hmap.Key.create "account_status"
    let branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_name"
    let dest_branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_name"
    let branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_ref"
    let dest_branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_ref"
    let client : S.Api.Client.t Hmap.key = Hmap.Key.create "client"
    let repo_tree_dest_branch : string list Hmap.key = Hmap.Key.create "repo_tree_dest_branch"
    let repo_tree_branch : string list Hmap.key = Hmap.Key.create "repo_tree_branch"

    let repo_config_system_defaults :
        Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t Hmap.key =
      Hmap.Key.create "repo_config_system_defaults"

    let repo_config_raw :
        (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
      Hmap.Key.create "repo_config_raw"

    let repo_config_with_provenance :
        (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
      Hmap.Key.create "repo_config_with_provenance"

    let repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Hmap.key =
      Hmap.Key.create "repo_config"

    let publish_repo_config : unit Hmap.key = Hmap.Key.create "publish_repo_config"
    let comment_id : int Hmap.key = Hmap.Key.create "comment_id"
    let pull_request_id : S.Api.Pull_request.Id.t Hmap.key = Hmap.Key.create "pull_request_id"

    let pull_request : (Terrat_change.Diff.t list, bool) S.Api.Pull_request.t Hmap.key =
      Hmap.Key.create "pull_request"

    let user : S.Api.User.t Hmap.key = Hmap.Key.create "user"
    let repo : S.Api.Repo.t Hmap.key = Hmap.Key.create "repo"
    let react_to_comment : unit Hmap.key = Hmap.Key.create "react_to_comment"

    (* Repo tree work manifest *)
    let repo_tree_wm_create = Hmap.Key.create "repo_tree_wm_create_or_update"
    let repo_tree_wm_initiate = Hmap.Key.create "repo_tree_wm_initiate"
    let repo_tree_wm_result = Hmap.Key.create "repo_tree_wm_result"
    let repo_tree_wm_completed = Hmap.Key.create "repo_tree_wm_completed"
    let built_repo_tree_branch : string list Hmap.key = Hmap.Key.create "built_repo_tree_branch"

    (* Context management *)
    let store_repository : unit Hmap.key = Hmap.Key.create "store_repository"
    let store_pull_request : unit Hmap.key = Hmap.Key.create "store_pull_request"
    let tag_query : Terrat_tag_query.t Hmap.key = Hmap.Key.create "tag_query"

    let job :
        (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t
        Hmap.key =
      Hmap.Key.create "job"

    (* API facing targets *)
    let update_context_for_pull_request : unit Hmap.key =
      Hmap.Key.create "update_context_for_pull_request"

    let eval_job : unit Hmap.key = Hmap.Key.create "eval_job"
  end

  module Tasks = struct
    let run ~name f s fetcher =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "%s: TASK : TIME : name=%s : time=%f" (B.State.job_id s) name t))
        (fun () ->
          let open Abb.Future.Infix_monad in
          Logs.info (fun m -> m "%s : TASK : START : name=%s" (B.State.job_id s) name);
          f s fetcher
          >>= function
          | Ok _ as r ->
              Logs.info (fun m -> m "%s : TASK : END : SUCCESS : name=%s" (B.State.job_id s) name);
              Abb.Future.return r
          | Error (#err as err) ->
              Logs.err (fun m ->
                  m "%s : TASK : END : FAILURE : name=%s : %a" (B.State.job_id s) name pp_err err);
              Abb.Future.return (Error err))

    let account_status =
      run ~name:"account_status" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          run_db s ~f:(fun db ->
              S.Db.query_account_status ~request_id:(B.State.job_id s) db account))

    let branch_name =
      run ~name:"branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_name pull_request)))

    let branch_ref =
      run ~name:"branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_ref pull_request)))

    let dest_branch_name =
      run ~name:"dest_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.base_branch_name pull_request)))

    let dest_branch_ref =
      run ~name:"dest_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request -> Abb.Future.return (Ok (S.Api.Pull_request.base_ref pull_request)))

    let client =
      run ~name:"client" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          S.Api.create_client ~request_id:(B.State.job_id s) s.B.State.config account)

    let built_repo_tree_branch =
      run ~name:"built_repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          run_db s ~f:(fun db ->
              S.Db.query_repo_tree
                ~request_id:(B.State.job_id s)
                ~base_ref:dest_branch_ref
                db
                account
                branch_ref)
          >>= function
          | Some tree -> Abb.Future.return (Ok tree)
          | None -> raise (Failure "nyi"))

    let repo_tree_branch =
      run ~name:"repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw
          >>= fun (_, repo_config_raw) ->
          let tree_builder = V1.tree_builder repo_config_raw in
          if tree_builder.V1.Tree_builder.enabled then fetch Keys.built_repo_tree_branch
          else
            Ira.(
              (fun client repo branch_ref -> (client, repo, branch_ref))
              <$> fetch Keys.client
              <*> fetch Keys.repo
              <*> fetch Keys.branch_ref)
            >>= fun (client, repo, branch_ref) ->
            S.Api.fetch_tree ~request_id:(B.State.job_id s) client repo branch_ref)

    let repo_tree_dest_branch =
      run ~name:"repo_tree_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client repo branch_ref -> (client, repo, branch_ref))
            <$> fetch Keys.client
            <*> fetch Keys.repo
            <*> fetch Keys.dest_branch_ref)
          >>= fun (client, repo, dest_branch_ref) ->
          S.Api.fetch_tree ~request_id:(B.State.job_id s) client repo dest_branch_ref)

    let repo_config_system_defaults =
      run ~name:"repo_config_system_defaults" (fun s _ ->
          let module V1 = Terrat_base_repo_config_v1 in
          match Terrat_config.infracost @@ S.Api.Config.config @@ s.B.State.config with
          | Some _ -> Abb.Future.return (Ok V1.default)
          | None ->
              let system_defaults =
                {
                  (V1.to_view V1.default) with
                  V1.View.cost_estimation = V1.Cost_estimation.make ~enabled:false ();
                }
              in
              Abb.Future.return (Ok (V1.of_view system_defaults)))

    let repo_config_raw =
      run ~name:"repo_config_raw" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client branch_ref system_defaults repo ->
              (client, branch_ref, system_defaults, repo))
            <$> fetch Keys.client
            <*> fetch Keys.branch_ref
            <*> fetch Keys.repo_config_system_defaults
            <*> fetch Keys.repo)
          >>= fun (client, branch_ref, system_defaults, repo) ->
          S.Repo_config.fetch_with_provenance
            ~system_defaults
            (B.State.job_id s)
            client
            repo
            branch_ref)

    let repo_config_with_provenance =
      run ~name:"repo_config_with_provenance" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun repo_config_raw pull_request repo_tree ->
              (repo_config_raw, pull_request, repo_tree))
            <$> fetch Keys.repo_config_raw
            <*> fetch Keys.pull_request
            <*> fetch Keys.repo_tree_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          let index = Terrat_base_repo_config_v1.Index.empty in
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : repo_config_with_provenance : derive : time=%f" (B.State.job_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:
                              (S.Api.Ref.to_string
                              @@ S.Api.Pull_request.base_branch_name pull_request)
                            ~branch:
                              (S.Api.Ref.to_string @@ S.Api.Pull_request.branch_name pull_request)
                            ())
                       ~index
                       ~file_list:repo_tree
                       repo_config_raw))
          >>= fun repo_config ->
          match Terrat_change_match3.synthesize_config ~index repo_config with
          | Ok _ -> Abb.Future.return (Ok (provenance, repo_config))
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let repo_config =
      run ~name:"repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.repo_config_with_provenance
          >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config))

    let publish_repo_config =
      run ~name:"publish_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client pull_request repo_config_with_provenance user () ->
              (client, pull_request, repo_config_with_provenance, user))
            <$> fetch Keys.client
            <*> fetch Keys.pull_request
            <*> fetch Keys.repo_config_with_provenance
            <*> fetch Keys.user
            <*> fetch Keys.react_to_comment)
          >>= fun (client, pull_request, repo_config_with_provenance, user) ->
          S.Comment.publish_comment
            ~request_id:(B.State.job_id s)
            client
            (S.Api.User.to_string user)
            pull_request
            (Msg.Repo_config repo_config_with_provenance))

    let react_to_comment =
      run ~name:"react_to_comment" (fun s { Bs.Fetcher.fetch } ->
          let open Abb.Future.Infix_monad in
          fetch Keys.comment_id
          >>= function
          | Ok comment_id ->
              let open Irm in
              Ira.(
                (fun comment_id pull_request client -> (comment_id, pull_request, client))
                <$> fetch Keys.comment_id
                <*> fetch Keys.pull_request
                <*> fetch Keys.client)
              >>= fun (comment_id, pull_request, client) ->
              S.Api.react_to_comment ~request_id:(B.State.job_id s) client pull_request comment_id
          | Error (`Missing_dep_err "comment_id") ->
              (* It's OK if no comment_id exists, this is an error we'll just ignore. *)
              Abb.Future.return (Ok ())
          | Error #err as err -> Abb.Future.return err)

    let pull_request =
      run ~name:"pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun account repo client pull_request_id -> (account, repo, client, pull_request_id))
            <$> fetch Keys.account
            <*> fetch Keys.repo
            <*> fetch Keys.client
            <*> fetch Keys.pull_request_id)
          >>= fun (account, repo, client, pull_request_id) ->
          S.Api.fetch_pull_request
            ~request_id:(B.State.job_id s)
            account
            client
            repo
            pull_request_id)

    let store_repository =
      run ~name:"store_repository" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          run_db s ~f:(fun db ->
              S.Db.store_account_repository ~request_id:(B.State.job_id s) db account repo))

    let store_pull_request =
      run ~name:"store_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          run_db s ~f:(fun db ->
              S.Db.store_pull_request ~request_id:(B.State.job_id s) db pull_request))

    (* User facing tasks *)
    let update_context_for_pull_request =
      run ~name:"update_context_for_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.((fun () () -> ()) <$> fetch Keys.store_repository <*> fetch Keys.store_pull_request)
          >>= fun () ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          run_db s ~f:(fun db ->
              S.Job_context.update_for_pull_request
                ~request_id:(B.State.job_id s)
                ~context_id:s.B.State.context.Tjc.Context.id
                db
                repo
                (S.Api.Pull_request.id pull_request)))

    let eval_job =
      run ~name:"eval_job" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          match job.Tjc.Job.type_ with
          | Tjc.Job.Type_.Apply { tag_query } -> raise (Failure "nyi")
          | Tjc.Job.Type_.Autoapply -> raise (Failure "nyi")
          | Tjc.Job.Type_.Autoplan -> raise (Failure "nyi")
          | Tjc.Job.Type_.Plan { tag_query } -> raise (Failure "nyi")
          | Tjc.Job.Type_.Repo_config -> fetch Keys.publish_repo_config
          | Tjc.Job.Type_.Unlock -> raise (Failure "nyi"))
  end

  let tasks_map =
    Hmap.empty
    |> Hmap.add (coerce Keys.account_status) Tasks.account_status
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.client) Tasks.client
    |> Hmap.add (coerce Keys.repo_tree_branch) Tasks.repo_tree_branch
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add (coerce Keys.repo_config_system_defaults) Tasks.repo_config_system_defaults
    |> Hmap.add (coerce Keys.repo_config_raw) Tasks.repo_config_raw
    |> Hmap.add (coerce Keys.repo_config_with_provenance) Tasks.repo_config_with_provenance
    |> Hmap.add (coerce Keys.repo_config) Tasks.repo_config
    |> Hmap.add (coerce Keys.publish_repo_config) Tasks.publish_repo_config
    |> Hmap.add (coerce Keys.react_to_comment) Tasks.react_to_comment
    |> Hmap.add (coerce Keys.pull_request) Tasks.pull_request
    |> Hmap.add (coerce Keys.update_context_for_pull_request) Tasks.update_context_for_pull_request
    |> Hmap.add (coerce Keys.store_repository) Tasks.store_repository
    |> Hmap.add (coerce Keys.store_pull_request) Tasks.store_pull_request
    |> Hmap.add (coerce Keys.eval_job) Tasks.eval_job

  let tasks =
    { Bs.Tasks.get = (fun s k -> Abb.Future.return (Ok (Hmap.find (coerce k) tasks_map))) }

  let rebuilder = { Bs.Rebuilder.run = (fun _s _k v _task _fetcher -> Abb.Future.return (Ok v)) }

  let log_err ~request_id fut =
    let open Abb.Future.Infix_monad in
    Abb.Future.await_bind
      (function
        | `Det (Ok ()) -> Abb.Future.return (Ok ())
        | `Det (Error (#err as err)) ->
            Logs.err (fun m -> m "%s : %a" request_id pp_err err);
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
               let store = Hmap.add Keys.job job store in
               let s = { B.State.context; job; config; store; storage; db } in
               match context.Tjc.Context.scope with
               | Tjc.Context.Scope.Setup ->
                   let open Irm in
                   Logs.info (fun m ->
                       m
                         "%s : SETUP_CONTEXT : context=%a"
                         (B.State.job_id s)
                         Uuidm.pp
                         context.Tjc.Context.id);
                   Bs.build rebuilder tasks Keys.update_context_for_pull_request (Bs.St.create s)
                   >>= fun () ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.job_id s) (Hmap.Key.info Keys.eval_job));
                   Bs.build rebuilder tasks Keys.eval_job (Bs.St.create s)
               | _ ->
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.job_id s) (Hmap.Key.info Keys.eval_job));
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
                   let store = Hmap.add Keys.job job store in
                   let s = { B.State.context; job; config; store; storage; db } in
                   Logs.info (fun m ->
                       m "%s : target=%s" (B.State.job_id s) (Hmap.Key.info Keys.eval_job));
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
