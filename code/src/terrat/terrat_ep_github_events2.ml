module Gw = Terrat_github_webhooks

module Metrics = struct
  module DefaultHistogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.005; 0.5; 1.0; 5.0; 10.0; 15.0; 20.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "ep_github_events"

  let events_duration_seconds =
    let help = "Number of seconds that handling an incoming event takes" in
    DefaultHistogram.v ~help ~namespace ~subsystem "events_duration_seconds"

  let events_total_family =
    let help = "Number of events that the system has received" in
    Prmths.Counter.v_labels
      ~label_names:[ "type"; "action" ]
      ~help
      ~namespace
      ~subsystem
      "events_total"

  let comment_events_total action = Prmths.Counter.labels events_total_family [ "comment"; action ]
  let pr_events_total action = Prmths.Counter.labels events_total_family [ "pr"; action ]

  let installation_events_total typ =
    Prmths.Counter.labels events_total_family [ "installation"; typ ]

  let events_concurrent =
    let help = "Number of events being handled right now" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "events_concurrent"

  let pgsql_pool_errors_total = Terrat_metrics.errors_total ~m:"ep_github_events" ~t:"pgsql_pool"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:"ep_github_events" ~t:"pgsql"
  let github_errors_total = Terrat_metrics.errors_total ~m:"ep_github_events" ~t:"github"

  let github_webhook_decode_errors_total =
    Terrat_metrics.errors_total ~m:"ep_github_events" ~t:"github_webhook_decode"
end

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let insert_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation.sql"
      /% Var.bigint "id"
      /% Var.text "login"
      /% Var.uuid "org"
      /% Var.text "target_type")

  let update_github_installation_unsuspend =
    Pgsql_io.Typed_sql.(
      sql /^ "update github_installations set state = 'installed' where id = $id" /% Var.bigint "id")

  let update_github_installation_uninstall =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_installations set state = 'uninstalled' where id = $id"
      /% Var.bigint "id")

  let update_github_installation_suspended =
    Pgsql_io.Typed_sql.(
      sql /^ "update github_installations set state = 'suspended' where id = $id" /% Var.bigint "id")

  let insert_github_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.text "owner"
      /% Var.text "name")

  let insert_org =
    Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "insert_org.sql" /% Var.text "name")

  let select_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.bigint
      /^ "select id from github_installations where id = $id"
      /% Var.bigint "id")

  let fail_running_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* run_kind *) Ret.text
      // (* id *) Ret.uuid
      // (* pull_number *) Ret.(option bigint)
      // (* sha *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest2.Run_type.of_string
      /^ read "github_fail_running_work_manifest.sql"
      /% Var.text "run_id")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ "select path, workspace from github_work_manifest_dirspaceflows where work_manifest = $id"
      /% Var.uuid "id")
end

module Tmpl = struct
  let read fname =
    fname
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> CCResult.get_exn
    |> fun tmpl -> Snabela.of_template tmpl []

  let terrateam_comment_tag_query_error = read "terrateam_comment_tag_query_error.tmpl"

  let terrateam_comment_unknown_action =
    let fname = "terrateam_comment_unknown_action.tmpl" in
    CCOption.get_exn_or fname (Terrat_files_tmpl.read fname)

  let terrateam_comment_help = read "terrateam_comment_help.tmpl"

  let action_failed =
    let fname = "github_action_failed.tmpl" in
    CCOption.get_exn_or fname (Terrat_files_tmpl.read fname)

  let unlock_failed_bad_id =
    CCOption.get_exn_or
      "github_unlock_failed_bad_id.tmpl"
      (Terrat_files_tmpl.read "github_unlock_failed_bad_id.tmpl")
end

let run_event f request_id config storage installation_id repo event =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_github_installation_repository
        (CCInt64.of_int (Terrat_github_evaluator2.Repo.id repo))
        (CCInt64.of_int installation_id)
        (Terrat_github_evaluator2.Repo.owner repo)
        (Terrat_github_evaluator2.Repo.name repo))
  >>= fun () ->
  let open Abb.Future.Infix_monad in
  Abb.Future.fork
    (Abb.Future.await_bind
       (function
         | `Det _ -> Abb.Future.return ()
         | `Exn (exn, _) ->
             Logs.err (fun m ->
                 m "GITHUB_EVENT : %s : ERROR : %s" request_id (Printexc.to_string exn));
             Abb.Future.return ()
         | `Aborted ->
             Logs.err (fun m -> m "GITHUB_EVENT : %s : ABORTED" request_id);
             Abb.Future.return ())
       (let open Abb.Future.Infix_monad in
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m -> m "GITHUB_EVENT : %s : EVALUATE_EVENT : time=%f" request_id time))
          (fun () -> f event)
        >>= fun _ ->
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m -> m "GITHUB_EVENT : %s : GITHUB_RUNNER : time=%f" request_id time))
          (fun () -> Terrat_github_evaluator2.Runner.(eval (make ~config ~request_id ~storage ())))))
  >>= fun _ -> Abb.Future.return (Ok ())

let run_terrform_event = run_event Terrat_github_evaluator2.Event.Terraform.eval
let run_unlock_event = run_event Terrat_github_evaluator2.Event.Unlock.eval
let run_index_event = run_event Terrat_github_evaluator2.Event.Index.eval
let run_repo_config_event = run_event Terrat_github_evaluator2.Event.Repo_config.eval
let run_push_event = run_event Terrat_github_evaluator2.Event.Push.eval

let perform_unlock_pr
    request_id
    config
    storage
    installation_id
    repository
    pull_number
    user
    unlock_ids =
  let open Abbs_future_combinators.Infix_result_monad in
  Logs.info (fun m ->
      m
        "GITHUB_EVENT : %s : UNLOCK : %s : %s  : %d : %s"
        request_id
        repository.Gw.Repository.owner.Gw.User.login
        repository.Gw.Repository.name
        pull_number
        (CCString.concat " " unlock_ids));
  match
    unlock_ids
    |> CCList.map (function
           | "drift" -> Ok Terrat_evaluator2.Unlock_id.Drift
           | s -> (
               match CCInt.of_string s with
               | Some n -> Ok (Terrat_evaluator2.Unlock_id.Pull_request n)
               | None -> Error s))
    |> CCResult.flatten_l
  with
  | Ok unlock_ids ->
      let unlock_ids =
        (* If the list is empty, then want to unlock the PR that this was issued
           in. *)
        match unlock_ids with
        | [] -> [ Terrat_evaluator2.Unlock_id.Pull_request pull_number ]
        | unlock_ids -> unlock_ids
      in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let repo =
        Terrat_github_evaluator2.Repo.make
          ~id:repository.Gw.Repository.id
          ~name:repository.Gw.Repository.name
          ~owner:repository.Gw.Repository.owner.Gw.User.login
          ()
      in
      let event =
        Terrat_github_evaluator2.Event.Unlock.make
          ~access_token
          ~config
          ~ids:unlock_ids
          ~installation_id
          ~pull_number
          ~repo
          ~request_id
          ~storage
          ~user
          ()
      in
      run_unlock_event request_id config storage installation_id repo event
  | Error _ ->
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      Terrat_github.with_client
        config
        (`Token access_token)
        (Terrat_github.publish_comment
           ~owner:repository.Gw.Repository.owner.Gw.User.login
           ~repo:repository.Gw.Repository.name
           ~pull_number
           ~body:Tmpl.unlock_failed_bad_id)

let process_installation request_id config storage = function
  | Gw.Installation_event.Installation_created created ->
      let open Abbs_future_combinators.Infix_result_monad in
      Prmths.Counter.inc_one (Metrics.installation_events_total "created");
      let installation = created.Gw.Installation_created.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : CREATE :  %d : %s"
            installation.Gw.Installation.id
            installation.Gw.Installation.account.Gw.User.login);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_github_installation
            ~f:CCFun.id
            (CCInt64.of_int installation.Gw.Installation.id)
          >>= function
          | [] -> (
              Pgsql_io.Prepared_stmt.fetch
                db
                Sql.insert_org
                ~f:CCFun.id
                installation.Gw.Installation.account.Gw.User.login
              >>= function
              | org_id :: _ ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_github_installation
                    (Int64.of_int installation.Gw.Installation.id)
                    installation.Gw.Installation.account.Gw.User.login
                    org_id
                    installation.Gw.Installation.account.Gw.User.type_
              | [] -> assert false)
          | _ :: _ -> Abb.Future.return (Ok ()))
  | Gw.Installation_event.Installation_deleted deleted ->
      let installation = deleted.Gw.Installation_deleted.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : UNINSTALL : %d : %s"
            installation.Gw.Installation.id
            installation.Gw.Installation.account.Gw.User.login);
      Prmths.Counter.inc_one (Metrics.installation_events_total "deleted");
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.update_github_installation_uninstall
            (Int64.of_int installation.Gw.Installation.id))
  | Gw.Installation_event.Installation_new_permissions_accepted installation_event ->
      Prmths.Counter.inc_one (Metrics.installation_events_total "new_permissions_accepted");
      let installation = installation_event.Gw.Installation_new_permissions_accepted.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : ACCEPTED_PERMISSIONS : %d : %s"
            installation.Gw.Installation.id
            installation.Gw.Installation.account.Gw.User.login);
      Abb.Future.return (Ok ())
  | Gw.Installation_event.Installation_suspend suspended ->
      let installation = suspended.Gw.Installation_suspend.installation in
      let module I = Gw.Installation_suspend.Installation_ in
      Logs.info (fun m ->
          m
            "INSTALLATION : SUSPENDED : %d : %s"
            installation.I.T.primary.I.T.Primary.id
            installation.I.T.primary.I.T.Primary.account.Gw.User.login);
      Prmths.Counter.inc_one (Metrics.installation_events_total "suspended");
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.update_github_installation_suspended
            (Int64.of_int installation.I.T.primary.I.T.Primary.id))
  | Gw.Installation_event.Installation_unsuspend unsuspend ->
      let installation = unsuspend.Gw.Installation_unsuspend.installation in
      let module I = Gw.Installation_unsuspend.Installation_ in
      Logs.info (fun m ->
          m
            "INSTALLATION : UNSUSPENDED : %d : %s"
            installation.I.T.primary.I.T.Primary.id
            installation.I.T.primary.I.T.Primary.account.Gw.User.login);
      Prmths.Counter.inc_one (Metrics.installation_events_total "unsuspended");
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.update_github_installation_unsuspend
            (Int64.of_int installation.I.T.primary.I.T.Primary.id))

let process_pull_request_event request_id config storage = function
  | Gw.Pull_request_event.Pull_request_opened
      {
        Gw.Pull_request_opened.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_opened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        sender;
        _;
      }
  | Gw.Pull_request_event.Pull_request_synchronize
      {
        Gw.Pull_request_synchronize.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request = Gw.Pull_request.{ number = pull_number; _ };
        sender;
        _;
      }
  | Gw.Pull_request_event.Pull_request_reopened
      {
        Gw.Pull_request_reopened.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request =
          Gw.Pull_request_reopened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        sender;
        _;
      }
  | Gw.Pull_request_event.Pull_request_ready_for_review
      {
        Gw.Pull_request_ready_for_review.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request =
          Gw.Pull_request_ready_for_review.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        sender;
        _;
      } ->
      Prmths.Counter.inc_one (Metrics.pr_events_total "update");
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            sender.Gw.User.login);
      let repo =
        Terrat_github_evaluator2.Repo.make
          ~id:repository.Gw.Repository.id
          ~name:repository.Gw.Repository.name
          ~owner:repository.Gw.Repository.owner.Gw.User.login
          ()
      in
      let event =
        Terrat_github_evaluator2.Event.Terraform.make
          ~config
          ~installation_id
          ~pull_number
          ~repo
          ~operation:Terrat_evaluator2.Tf_operation.(Plan Auto)
          ~request_id
          ~storage
          ~tag_query:Terrat_tag_query.any
          ~user:sender.Gw.User.login
          ()
      in
      run_terrform_event request_id config storage installation_id repo event
  | Gw.Pull_request_event.Pull_request_opened _ -> failwith "Invalid pull_request_open event"
  | Gw.Pull_request_event.Pull_request_synchronize _ ->
      failwith "Invalid pull_request_synchronize event"
  | Gw.Pull_request_event.Pull_request_reopened _ -> failwith "Invalid pull_request_reopened event"
  | Gw.Pull_request_event.Pull_request_closed
      {
        Gw.Pull_request_closed.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_closed.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        sender;
        _;
      } ->
      Prmths.Counter.inc_one (Metrics.pr_events_total "close");
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : PULL_REQUEST_CLOSED_EVENT : owner=%s : repo=%s : sender=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            sender.Gw.User.login);
      let repo =
        Terrat_github_evaluator2.Repo.make
          ~id:repository.Gw.Repository.id
          ~name:repository.Gw.Repository.name
          ~owner:repository.Gw.Repository.owner.Gw.User.login
          ()
      in
      let event =
        Terrat_github_evaluator2.Event.Terraform.make
          ~config
          ~installation_id
          ~pull_number
          ~repo
          ~operation:Terrat_evaluator2.Tf_operation.(Apply Auto)
          ~request_id
          ~storage
          ~tag_query:Terrat_tag_query.any
          ~user:sender.Gw.User.login
          ()
      in
      run_terrform_event request_id config storage installation_id repo event
  | Gw.Pull_request_event.Pull_request_closed _ -> failwith "Invalid pull_request_closed event"
  | Gw.Pull_request_event.Pull_request_assigned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_ASSIGNED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_auto_merge_disabled _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_AUTO_MERGE_DISABLED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_auto_merge_enabled _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_AUTO_MERGE_ENABLED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_converted_to_draft _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_CONVERTED_TO_DRAFT" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_edited _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_EDITED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_labeled _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_LABELED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_locked _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_LOCKED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_milestoned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_MILESTONED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_ready_for_review _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_READY_FOR_REVIEW" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_review_request_removed _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_REVIEW_REQUEST_REMOVED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_review_requested _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_REVIEW_REQUESTED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unassigned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNASSIGNED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unlabeled _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNLABELED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unlocked _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNLOCKED" request_id);
      Abb.Future.return (Ok ())

let process_issue_comment request_id config storage = function
  | Gw.Issue_comment_event.Issue_comment_created
      {
        Gw.Issue_comment_created.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        comment;
        issue =
          Gw.Issue_comment_created.Issue_.T.
            { primary = Primary.{ number = pull_number; pull_request = Some _; _ }; _ };
        sender;
        _;
      } -> (
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : COMMENT_CREATED_EVENT : owner=%s : repo=%s : sender=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            sender.Gw.User.login);
      match Terrat_comment.parse comment.Gw.Issue_comment.body with
      | Ok (Terrat_comment.Unlock ids) ->
          Prmths.Counter.inc_one (Metrics.comment_events_total "unlock");
          perform_unlock_pr
            request_id
            config
            storage
            installation_id
            repository
            pull_number
            sender.Gw.User.login
            ids
      | Ok (Terrat_comment.Plan { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "plan");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Terraform.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~operation:Terrat_evaluator2.Tf_operation.(Plan Manual)
              ~request_id
              ~storage
              ~tag_query
              ~user:sender.Gw.User.login
              ()
          in
          run_terrform_event request_id config storage installation_id repo event
      | Ok (Terrat_comment.Apply { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "apply");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Terraform.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~operation:Terrat_evaluator2.Tf_operation.(Apply Manual)
              ~request_id
              ~storage
              ~tag_query
              ~user:sender.Gw.User.login
              ()
          in
          run_terrform_event request_id config storage installation_id repo event
      | Ok (Terrat_comment.Apply_autoapprove { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "apply_autoapprove");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Terraform.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~operation:Terrat_evaluator2.Tf_operation.Apply_autoapprove
              ~request_id
              ~storage
              ~tag_query
              ~user:sender.Gw.User.login
              ()
          in
          run_terrform_event request_id config storage installation_id repo event
      | Ok (Terrat_comment.Apply_force { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "apply_force");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Terraform.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~operation:Terrat_evaluator2.Tf_operation.Apply_force
              ~request_id
              ~storage
              ~tag_query
              ~user:sender.Gw.User.login
              ()
          in
          run_terrform_event request_id config storage installation_id repo event
      | Ok Terrat_comment.Help -> (
          Prmths.Counter.inc_one (Metrics.comment_events_total "help");
          let kv = Snabela.Kv.Map.of_list [] in
          match Snabela.apply Tmpl.terrateam_comment_help kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.publish_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~pull_number
                   ~body)
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m "GITHUB_EVENT : %s : TMPL_ERROR : HELP : %s" request_id (Snabela.show_err err));
              Abb.Future.return (Ok ()))
      | Ok (Terrat_comment.Feedback msg) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "feedback");
          Logs.info (fun m ->
              m
                "GITHUB_EVENT : %s : FEEDBACK : owner=%s : repo=%s : pull_number=%d : user=%s : %s"
                request_id
                repository.Gw.Repository.owner.Gw.User.login
                repository.Gw.Repository.name
                pull_number
                comment.Gw.Issue_comment.user.Gw.User.login
                msg);
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.with_client
            config
            (`Token access_token)
            (Terrat_github.react_to_comment
               ~content:"heart"
               ~owner:repository.Gw.Repository.owner.Gw.User.login
               ~repo:repository.Gw.Repository.name
               ~comment_id:comment.Gw.Issue_comment.id)
          >>= fun () -> Abb.Future.return (Ok ())
      | Ok Terrat_comment.Repo_config ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "repo_config");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Repo_config.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~request_id
              ~user:sender.Gw.User.login
              ~storage
              ()
          in
          run_repo_config_event request_id config storage installation_id repo event
      | Ok Terrat_comment.Index ->
          let open Abbs_future_combinators.Infix_result_monad in
          Prmths.Counter.inc_one (Metrics.comment_events_total "index");
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.react_to_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~comment_id:comment.Gw.Issue_comment.id))
          >>= fun () ->
          let repo =
            Terrat_github_evaluator2.Repo.make
              ~id:repository.Gw.Repository.id
              ~name:repository.Gw.Repository.name
              ~owner:repository.Gw.Repository.owner.Gw.User.login
              ()
          in
          let event =
            Terrat_github_evaluator2.Event.Index.make
              ~config
              ~installation_id
              ~pull_number
              ~repo
              ~request_id
              ~storage
              ~user:sender.Gw.User.login
              ()
          in
          run_index_event request_id config storage installation_id repo event
      | Error `Not_terrateam ->
          Prmths.Counter.inc_one (Metrics.comment_events_total "not_terrateam");
          Abb.Future.return (Ok ())
      | Error (`Tag_query_error (_, err)) -> (
          Prmths.Counter.inc_one (Metrics.comment_events_total "tag_query");
          let kv = Snabela.Kv.(Map.of_list [ ("err", string err) ]) in
          match Snabela.apply Tmpl.terrateam_comment_tag_query_error kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m "GITHUB_EVENT : %s : COMMENT_ERROR : TAG_QUERY_ERROR : %s" request_id err);
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.with_client
                config
                (`Token access_token)
                (Terrat_github.publish_comment
                   ~owner:repository.Gw.Repository.owner.Gw.User.login
                   ~repo:repository.Gw.Repository.name
                   ~pull_number
                   ~body)
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m
                    "GITHUB_EVENT : %s : TMPL_ERROR : TAG_QUERY_ERROR : %s"
                    request_id
                    (Snabela.show_err err));
              Abb.Future.return (Ok ()))
      | Error (`Unknown_action action) ->
          Prmths.Counter.inc_one (Metrics.comment_events_total "unknown_action");
          let open Abbs_future_combinators.Infix_result_monad in
          Logs.info (fun m ->
              m "GITHUB_EVENT : %s : COMMENT_ERROR : UNKNOWN_ACTION : %s" request_id action);
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.with_client
            config
            (`Token access_token)
            (Terrat_github.publish_comment
               ~owner:repository.Gw.Repository.owner.Gw.User.login
               ~repo:repository.Gw.Repository.name
               ~pull_number
               ~body:Tmpl.terrateam_comment_unknown_action))
  | Gw.Issue_comment_event.Issue_comment_created _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_CREATED" request_id);
      Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_comment_deleted _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_DELETED" request_id);
      Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_comment_edited _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_EDITED" request_id);
      Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_any _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE" request_id);
      Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
      Abb.Future.return (Ok ())

let process_workflow_job_failure config storage access_token run_id repository =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      (* Including the repository here just in case run id's are recycled,
         we will limit ourselves to jobs in the correct repository.  Worst
         case is doing something in another customer's repository *)
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.fail_running_work_manifest
        ~f:(fun run_kind id pull_number sha run_type -> (run_kind, id, pull_number, sha, run_type))
        run_id
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | ((run_kind, work_manifest_id, _pull_number, _sha, _run_type) as r) :: _ ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_dirspaces
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            work_manifest_id
          >>= fun dirspaces -> Abb.Future.return (Ok (Some (r, dirspaces))))
  >>= function
  | Some (("pr", work_manifest_id, Some pull_number, sha, run_type), dirspaces) ->
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : %s : %s : %Ld"
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            pull_number);
      (* We successfully failed something *)
      Terrat_github.with_client
        config
        (`Token access_token)
        (Terrat_github.publish_comment
           ~owner:repository.Gw.Repository.owner.Gw.User.login
           ~repo:repository.Gw.Repository.name
           ~pull_number:(CCInt64.to_int pull_number)
           ~body:Tmpl.action_failed)
      >>= fun () ->
      let unified_run_type =
        Terrat_work_manifest2.(
          run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
      in
      let target_url =
        Printf.sprintf
          "https://github.com/%s/%s/actions/runs/%s"
          repository.Gw.Repository.owner.Gw.User.login
          repository.Gw.Repository.name
          run_id
      in
      let commit_statuses =
        let module T = Terrat_github.Commit_status.Create.T in
        let aggregate =
          T.make
            ~target_url
            ~description:"Failed"
            ~context:(Printf.sprintf "terrateam %s" unified_run_type)
            ~state:"failure"
            ()
        in
        let dirspaces =
          CCList.map
            (fun Terrat_change.Dirspace.{ dir; workspace } ->
              T.make
                ~target_url
                ~description:"Failed"
                ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type dir workspace)
                ~state:"failure"
                ())
            dirspaces
        in
        aggregate :: dirspaces
      in
      let open Abb.Future.Infix_monad in
      Abb.Future.fork
        (Abbs_time_it.run
           (fun t ->
             Logs.info (fun m ->
                 m "GITHUB_EVENT : WORKFLOW_JOB_FAIL_COMMIT_STATUS : %s : %f" run_id t))
           (fun () ->
             Terrat_github.with_client
               config
               (`Token access_token)
               (Terrat_github.Commit_status.create
                  ~owner:repository.Gw.Repository.owner.Gw.User.login
                  ~repo:repository.Gw.Repository.name
                  ~sha
                  ~creates:commit_statuses)))
      >>= fun _ -> Abb.Future.return (Ok ())
  | Some (("drift", work_manifest_id, _, _, _), _) ->
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : %s : %s : %a : DRIFT"
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            Uuidm.pp
            work_manifest_id);
      Abb.Future.return (Ok ())
  | Some (("index", work_manifest_id, _, _, _), _) ->
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : %s : %s : %a : INDEX"
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            Uuidm.pp
            work_manifest_id);
      Abb.Future.return (Ok ())
  | Some _ | None ->
      (* Nothing to fail *)
      Logs.warn (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : NO_MATCHES : %s : %s : %s"
            run_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name);
      Abb.Future.return (Ok ())

let process_workflow_job request_id config storage = function
  | Gw.Workflow_job_event.
      {
        installation = Some Gw.Installation_lite.{ id = installation_id; _ };
        repository;
        workflow_job = Gw.Workflow_job.{ run_id; conclusion = Some "failure"; _ };
        _;
      } ->
      (* We only handle failures specially because only on failure is it possible
         that the action did not communicate back the result to the service. *)
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let open Abb.Future.Infix_monad in
      process_workflow_job_failure config storage access_token (CCInt.to_string run_id) repository
      >>= fun ret ->
      Abb.Future.fork Terrat_github_evaluator2.Runner.(eval (make ~request_id ~config ~storage ()))
      >>= fun _ -> Abb.Future.return ret
  | _ -> Abb.Future.return (Ok ())

let process_push_event request_id config storage event =
  let repository = event.Gw.Push_event.repository in
  let default_branch = repository.Gw.Repository.default_branch in
  let ref_ = event.Gw.Push_event.ref_ in
  let default_ref = "refs/heads/" ^ default_branch in
  match event.Gw.Push_event.installation with
  | Some installation_lite when CCString.equal ref_ default_ref ->
      let installation_id = installation_lite.Gw.Installation_lite.id in
      let repo =
        Terrat_github_evaluator2.Repo.make
          ~id:repository.Gw.Repository.id
          ~name:repository.Gw.Repository.name
          ~owner:repository.Gw.Repository.owner.Gw.User.login
          ()
      in
      let event =
        Terrat_github_evaluator2.Event.Push.make
          ~branch:(Terrat_github_evaluator2.Ref.of_string default_branch)
          ~config
          ~installation_id
          ~repo
          ~request_id
          ~storage
          ()
      in
      run_push_event request_id config storage installation_id repo event
  | Some _ | None ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : PUSH_EVENT : NOOP" request_id);
      Abb.Future.return (Ok ())

let handle_error ctx = function
  | #Pgsql_pool.err as err ->
      Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Pgsql_io.err as err ->
      Prmths.Counter.inc_one Metrics.pgsql_errors_total;
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Terrat_github.get_installation_access_token_err as err ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_get_installation_access_token_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Terrat_github.publish_comment_err as err ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_publish_comment_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | `Repo_config_err err ->
      Logs.err (fun m -> m "GITHUB_EVENT : %s : ERROR : REPO_CONFIG : %s" (Brtl_ctx.token ctx) err);
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Abb_process.check_output_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Abb_process.show_check_output_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | `Error ->
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

let process_event_handler config storage ctx f =
  let open Abb.Future.Infix_monad in
  f ()
  >>= function
  | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Error err -> handle_error ctx err

let post config storage ctx =
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  let body = Brtl_ctx.body ctx in
  Metrics.DefaultHistogram.time Metrics.events_duration_seconds (fun () ->
      Prmths.Gauge.track_inprogress Metrics.events_concurrent (fun () ->
          match
            Terrat_github_webhooks_decoder.run
              ?secret:(Terrat_config.github_webhook_secret config)
              headers
              body
          with
          | Ok (Gw.Event.Installation_event installation_event) ->
              process_event_handler config storage ctx (fun () ->
                  process_installation (Brtl_ctx.token ctx) config storage installation_event)
          | Ok (Gw.Event.Pull_request_event pull_request_event) ->
              process_event_handler config storage ctx (fun () ->
                  process_pull_request_event (Brtl_ctx.token ctx) config storage pull_request_event)
          | Ok (Gw.Event.Issue_comment_event event) ->
              process_event_handler config storage ctx (fun () ->
                  process_issue_comment (Brtl_ctx.token ctx) config storage event)
          | Ok (Gw.Event.Workflow_job_event event) ->
              process_event_handler config storage ctx (fun () ->
                  process_workflow_job (Brtl_ctx.token ctx) config storage event)
          | Ok (Gw.Event.Push_event event) ->
              process_event_handler config storage ctx (fun () ->
                  process_push_event (Brtl_ctx.token ctx) config storage event)
          | Ok (Gw.Event.Workflow_run_event _) ->
              Logs.debug (fun m ->
                  m "GITHUB_EVENT : %s : NOOP : WORKFLOW_RUN_EVENT" (Brtl_ctx.token ctx));
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
          | Ok (Gw.Event.Installation_repositories_event _)
          | Ok (Gw.Event.Workflow_dispatch_event _) ->
              Logs.debug (fun m ->
                  m
                    "GITHUB_EVENT : %s : NOOP : INSTALLATION_REPOSITORIES_EVENT"
                    (Brtl_ctx.token ctx));
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
          | Error (#Terrat_github_webhooks_decoder.err as err) ->
              Prmths.Counter.inc_one Metrics.github_webhook_decode_errors_total;
              Logs.warn (fun m ->
                  m
                    "GITHUB_EVENT : %s : UNKNOWN_EVENT : %s"
                    (Brtl_ctx.token ctx)
                    (Terrat_github_webhooks_decoder.show_err err));
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
