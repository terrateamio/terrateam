let src = Logs.Src.create "vcs_service_github_ep_events"

module Logs = (val Logs.src_log src : Logs.LOG)

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

module Make (P : Terrat_vcs_provider2_github.S) = struct
  module Evaluator = Terrat_vcs_event_evaluator.Make (P)
  module Gw = Terrat_github_webhooks

  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

    let insert_github_installation =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_installation.sql"
        /% Var.bigint "id"
        /% Var.text "login"
        /% Var.uuid "org"
        /% Var.text "target_type"
        /% Var.text "tier")

    let update_github_installation_unsuspend =
      Pgsql_io.Typed_sql.(
        sql
        /^ "update github_installations set state = 'installed' where id = $id"
        /% Var.bigint "id")

    let update_github_installation_uninstall =
      Pgsql_io.Typed_sql.(
        sql
        /^ "update github_installations set state = 'uninstalled' where id = $id"
        /% Var.bigint "id")

    let update_github_installation_suspended =
      Pgsql_io.Typed_sql.(
        sql
        /^ "update github_installations set state = 'suspended' where id = $id"
        /% Var.bigint "id")

    let insert_org =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        /^ read "insert_org.sql"
        /% Var.text "name")

    let select_github_installation =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        /^ "select id from github_installations where id = $id"
        /% Var.bigint "id")

    let select_work_manifest_by_run_id =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        /^ "select id from work_manifests where run_id = $run_id"
        /% Var.text "run_id")
  end

  module Tmpl = struct
    let read fname =
      fname
      |> Terrat_files_github_tmpl.read
      |> CCOption.get_exn_or fname
      |> Snabela.Template.of_utf8_string
      |> CCResult.get_exn
      |> fun tmpl -> Snabela.of_template tmpl []

    let terrateam_comment_tag_query_error = read "terrateam_comment_tag_query_error.tmpl"

    let terrateam_comment_unknown_action =
      let fname = "terrateam_comment_unknown_action.tmpl" in
      CCOption.get_exn_or fname (Terrat_files_github_tmpl.read fname)
  end

  let process_installation request_id config storage = function
    | Gw.Installation_event.Installation_created created ->
        let open Abbs_future_combinators.Infix_result_monad in
        Prmths.Counter.inc_one (Metrics.installation_events_total "created");
        let installation = created.Gw.Installation_created.installation in
        Logs.info (fun m ->
            m
              "INSTALLATION : CREATE :  account=%d : org=%s : sender=%s"
              installation.Gw.Installation.id
              installation.Gw.Installation.account.Gw.User.login
              created.Gw.Installation_created.sender.Gw.User.login);
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
                      (Terrat_config.default_tier @@ P.Api.Config.config config)
                | [] -> assert false)
            | _ :: _ -> Abb.Future.return (Ok ()))
    | Gw.Installation_event.Installation_deleted deleted ->
        let installation = deleted.Gw.Installation_deleted.installation in
        Logs.info (fun m ->
            m
              "INSTALLATION : UNINSTALL : account=%d : org=%s : sender=%s"
              installation.Gw.Installation.id
              installation.Gw.Installation.account.Gw.User.login
              deleted.Gw.Installation_deleted.sender.Gw.User.login);
        Prmths.Counter.inc_one (Metrics.installation_events_total "deleted");
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute
              db
              Sql.update_github_installation_uninstall
              (Int64.of_int installation.Gw.Installation.id))
    | Gw.Installation_event.Installation_new_permissions_accepted installation_event ->
        Prmths.Counter.inc_one (Metrics.installation_events_total "new_permissions_accepted");
        let installation =
          installation_event.Gw.Installation_new_permissions_accepted.installation
        in
        Logs.info (fun m ->
            m
              "INSTALLATION : ACCEPTED_PERMISSIONS : account=%d : org=%s : sender=%s"
              installation.Gw.Installation.id
              installation.Gw.Installation.account.Gw.User.login
              installation_event.Gw.Installation_new_permissions_accepted.sender.Gw.User.login);
        Abb.Future.return (Ok ())
    | Gw.Installation_event.Installation_suspend suspended ->
        let installation = suspended.Gw.Installation_suspend.installation in
        let module I = Gw.Installation_suspend.Installation_ in
        Logs.info (fun m ->
            m
              "INSTALLATION : SUSPENDED : account=%d : org=%s : sender=%s"
              installation.I.T.primary.I.T.Primary.id
              installation.I.T.primary.I.T.Primary.account.Gw.User.login
              suspended.Gw.Installation_suspend.sender.Gw.User.login);
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
              "INSTALLATION : UNSUSPENDED : account-%d : org=%s : sender=%s"
              installation.I.T.primary.I.T.Primary.id
              installation.I.T.primary.I.T.Primary.account.Gw.User.login
              unsuspend.Gw.Installation_unsuspend.sender.Gw.User.login);
        Prmths.Counter.inc_one (Metrics.installation_events_total "unsuspended");
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute
              db
              Sql.update_github_installation_unsuspend
              (Int64.of_int installation.I.T.primary.I.T.Primary.id))

  let process_pull_request_event request_id config storage = function
    | Gw.Pull_request_event.Pull_request_opened
        {
          Gw.Pull_request_opened.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          pull_request =
            Gw.Pull_request_opened.Pull_request_.T.
              { primary = Primary.{ number = pull_request_id; _ }; _ };
          repository;
          sender;
          _;
        } ->
        Prmths.Counter.inc_one (Metrics.pr_events_total "open");
        Logs.info (fun m ->
            m
              "%s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        let account = P.Api.Account.make installation_id in
        let user = P.Api.User.make sender.Gw.User.login in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        Evaluator.run_pull_request_open
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~pull_request_id
          ()
    | Gw.Pull_request_event.Pull_request_synchronize
        {
          Gw.Pull_request_synchronize.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          repository;
          pull_request = Gw.Pull_request.{ number = pull_request_id; _ };
          sender;
          _;
        } ->
        Prmths.Counter.inc_one (Metrics.pr_events_total "sync");
        Logs.info (fun m ->
            m
              "%s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        let account = P.Api.Account.make installation_id in
        let user = P.Api.User.make sender.Gw.User.login in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        Evaluator.run_pull_request_sync
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~pull_request_id
          ()
    | Gw.Pull_request_event.Pull_request_reopened
        {
          Gw.Pull_request_reopened.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          repository;
          pull_request =
            Gw.Pull_request_reopened.Pull_request_.T.
              { primary = Primary.{ number = pull_request_id; _ }; _ };
          sender;
          _;
        } ->
        Prmths.Counter.inc_one (Metrics.pr_events_total "reopen");
        Logs.info (fun m ->
            m
              "%s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        let account = P.Api.Account.make installation_id in
        let user = P.Api.User.make sender.Gw.User.login in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        Evaluator.run_pull_request_open
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~pull_request_id
          ()
    | Gw.Pull_request_event.Pull_request_ready_for_review
        {
          Gw.Pull_request_ready_for_review.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          repository;
          pull_request =
            Gw.Pull_request_ready_for_review.Pull_request_.T.
              { primary = Primary.{ number = pull_request_id; _ }; _ };
          sender;
          _;
        } ->
        Prmths.Counter.inc_one (Metrics.pr_events_total "ready_for_review");
        Logs.info (fun m ->
            m
              "%s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        let account = P.Api.Account.make installation_id in
        let user = P.Api.User.make sender.Gw.User.login in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        Evaluator.run_pull_request_ready_for_review
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~pull_request_id
          ()
    | Gw.Pull_request_event.Pull_request_opened _ -> failwith "Invalid pull_request_open event"
    | Gw.Pull_request_event.Pull_request_synchronize _ ->
        failwith "Invalid pull_request_synchronize event"
    | Gw.Pull_request_event.Pull_request_reopened _ ->
        failwith "Invalid pull_request_reopened event"
    | Gw.Pull_request_event.Pull_request_closed
        {
          Gw.Pull_request_closed.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          pull_request =
            Gw.Pull_request_closed.Pull_request_.T.
              { primary = Primary.{ number = pull_request_id; _ }; _ };
          repository;
          sender;
          _;
        } ->
        Prmths.Counter.inc_one (Metrics.pr_events_total "close");
        Logs.info (fun m ->
            m
              "%s : PULL_REQUEST_CLOSED_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        let account = P.Api.Account.make installation_id in
        let user = P.Api.User.make sender.Gw.User.login in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        Evaluator.run_pull_request_close
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~pull_request_id
          ()
    | Gw.Pull_request_event.Pull_request_closed _ -> failwith "Invalid pull_request_closed event"
    | Gw.Pull_request_event.Pull_request_assigned _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_ASSIGNED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_auto_merge_disabled _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_AUTO_MERGE_DISABLED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_auto_merge_enabled _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_AUTO_MERGE_ENABLED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_converted_to_draft _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_CONVERTED_TO_DRAFT" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_edited _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_EDITED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_labeled _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_LABELED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_locked _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_LOCKED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_milestoned _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_MILESTONED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_ready_for_review _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_READY_FOR_REVIEW" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_review_request_removed _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_REVIEW_REQUEST_REMOVED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_review_requested _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_REVIEW_REQUESTED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_unassigned _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_UNASSIGNED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_unlabeled _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_UNLABELED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_unlocked _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_UNLOCKED" request_id);
        Abb.Future.return (Ok ())
    | Gw.Pull_request_event.Pull_request_review_submitted _ ->
        Logs.debug (fun m -> m "%s : NOOP : PULL_REQUEST_REVIEW_SUBMITTED" request_id);
        Abb.Future.return (Ok ())

  let process_issue_comment request_id config storage = function
    | Gw.Issue_comment_event.Issue_comment_created
        {
          Gw.Issue_comment_created.installation =
            Some { Gw.Installation_lite.id = installation_id; _ };
          repository;
          comment = { Gw.Issue_comment.id = comment_id; body = comment_body; _ };
          issue =
            Gw.Issue_comment_created.Issue_.T.
              { primary = Primary.{ number = pull_request_id; pull_request = Some _; _ }; _ };
          sender;
          _;
        } -> (
        Logs.info (fun m ->
            m
              "%s : COMMENT_CREATED_EVENT : owner=%s : repo=%s : sender=%s"
              request_id
              repository.Gw.Repository.owner.Gw.User.login
              repository.Gw.Repository.name
              sender.Gw.User.login);
        match Terrat_comment.parse comment_body with
        | Ok comment ->
            let account = P.Api.Account.make installation_id in
            let user = P.Api.User.make sender.Gw.User.login in
            let repo =
              P.Api.Repo.make
                ~id:repository.Gw.Repository.id
                ~name:repository.Gw.Repository.name
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ()
            in
            Evaluator.run_pull_request_comment
              ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
              ~account
              ~user
              ~comment
              ~repo
              ~pull_request_id
              ~comment_id
              ()
        | Error `Not_terrateam ->
            Prmths.Counter.inc_one (Metrics.comment_events_total "not_terrateam");
            Abb.Future.return (Ok ())
        | Error (`Tag_query_error (_, err)) -> (
            Prmths.Counter.inc_one (Metrics.comment_events_total "tag_query");
            let kv = Snabela.Kv.(Map.of_list [ ("err", string err) ]) in
            match Snabela.apply Tmpl.terrateam_comment_tag_query_error kv with
            | Ok body ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.info (fun m -> m "%s : COMMENT_ERROR : TAG_QUERY_ERROR : %s" request_id err);
                Terrat_github.get_installation_access_token
                  (P.Api.Config.vcs_config config)
                  installation_id
                >>= fun access_token ->
                Terrat_github.with_client
                  (P.Api.Config.vcs_config config)
                  (`Token access_token)
                  (Terrat_github.publish_comment
                     ~owner:repository.Gw.Repository.owner.Gw.User.login
                     ~repo:repository.Gw.Repository.name
                     ~pull_number:pull_request_id
                     ~body)
            | Error (#Snabela.err as err) ->
                Logs.err (fun m ->
                    m "%s : TMPL_ERROR : TAG_QUERY_ERROR : %s" request_id (Snabela.show_err err));
                Abb.Future.return (Ok ()))
        | Error (`Unknown_action action) ->
            Prmths.Counter.inc_one (Metrics.comment_events_total "unknown_action");
            let open Abbs_future_combinators.Infix_result_monad in
            Logs.info (fun m -> m "%s : COMMENT_ERROR : UNKNOWN_ACTION : %s" request_id action);
            Terrat_github.get_installation_access_token
              (P.Api.Config.vcs_config config)
              installation_id
            >>= fun access_token ->
            Terrat_github.with_client
              (P.Api.Config.vcs_config config)
              (`Token access_token)
              (Terrat_github.publish_comment
                 ~owner:repository.Gw.Repository.owner.Gw.User.login
                 ~repo:repository.Gw.Repository.name
                 ~pull_number:pull_request_id
                 ~body:Tmpl.terrateam_comment_unknown_action))
    | Gw.Issue_comment_event.Issue_comment_created _ ->
        Logs.debug (fun m -> m "%s : NOOP : ISSUE_COMMENT_CREATED" request_id);
        Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
        Abb.Future.return (Ok ())
    | Gw.Issue_comment_event.Issue_comment_deleted _ ->
        Logs.debug (fun m -> m "%s : NOOP : ISSUE_COMMENT_DELETED" request_id);
        Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
        Abb.Future.return (Ok ())
    | Gw.Issue_comment_event.Issue_comment_edited _ ->
        Logs.debug (fun m -> m "%s : NOOP : ISSUE_COMMENT_EDITED" request_id);
        Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
        Abb.Future.return (Ok ())
    | Gw.Issue_comment_event.Issue_any _ ->
        Logs.debug (fun m -> m "%s : NOOP : ISSUE" request_id);
        Prmths.Counter.inc_one (Metrics.comment_events_total "noop");
        Abb.Future.return (Ok ())

  let process_workflow_job request_id config storage event =
    match event with
    | Gw.Workflow_job_event.
        {
          installation = Some Gw.Installation_lite.{ id = installation_id; _ };
          repository;
          workflow_job = Gw.Workflow_job.{ run_id; conclusion = Some "failure"; _ };
          _;
        } -> (
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_work_manifest_by_run_id
              ~f:CCFun.id
              (CCInt.to_string run_id)
            >>= function
            | work_manifest_id :: _ -> Abb.Future.return (Ok (Some work_manifest_id))
            | [] -> Abb.Future.return (Ok None))
        >>= function
        | Some work_manifest_id ->
            Evaluator.run_work_manifest_failure
              ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
              work_manifest_id
        | None ->
            Logs.info (fun m ->
                m
                  "%s : WORK_MANIFEST_FAILURE : NOT_FOUND : account=%d : run_id=%d"
                  request_id
                  installation_id
                  run_id);
            Abb.Future.return (Ok ()))
    | _ -> Abb.Future.return (Ok ())

  let process_push_event request_id config storage event =
    let repository = event.Gw.Push_event.repository in
    let default_branch = repository.Gw.Repository.default_branch in
    let ref_ = event.Gw.Push_event.ref_ in
    let default_ref = "refs/heads/" ^ default_branch in
    match event.Gw.Push_event.installation with
    | Some installation_lite when CCString.equal ref_ default_ref ->
        let installation_id = installation_lite.Gw.Installation_lite.id in
        let account = P.Api.Account.make installation_id in
        let repo =
          P.Api.Repo.make
            ~id:repository.Gw.Repository.id
            ~name:repository.Gw.Repository.name
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ()
        in
        let user = P.Api.User.make event.Gw.Push_event.sender.Gw.User.login in
        Evaluator.run_push
          ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
          ~account
          ~user
          ~repo
          ~branch:(P.Api.Ref.of_string default_branch)
          ()
    | Some _ | None ->
        Logs.debug (fun m -> m "%s : PUSH_EVENT : NOOP" request_id);
        Abb.Future.return (Ok ())

  let handle_error ctx = function
    | #Pgsql_pool.err as err ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m -> m "%s : ERROR : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | #Pgsql_io.err as err ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "%s : ERROR : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | #Githubc2_abb.call_err as err ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m -> m "%s : ERROR : %a" (Brtl_ctx.token ctx) Githubc2_abb.pp_call_err err);
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | #Terrat_github.publish_comment_err as err ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m "%s : ERROR : %a" (Brtl_ctx.token ctx) Terrat_github.pp_publish_comment_err err);
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | #Terrat_github.get_installation_access_token_err as err ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "%s : ERROR : %a"
              (Brtl_ctx.token ctx)
              Terrat_github.pp_get_installation_access_token_err
              err);
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
                ?secret:(Terrat_config.Github.webhook_secret @@ P.Api.Config.vcs_config config)
                headers
                body
            with
            | Ok (Gw.Event.Installation_event installation_event) ->
                process_event_handler config storage ctx (fun () ->
                    process_installation (Brtl_ctx.token ctx) config storage installation_event)
            | Ok (Gw.Event.Pull_request_event pull_request_event) ->
                process_event_handler config storage ctx (fun () ->
                    process_pull_request_event
                      (Brtl_ctx.token ctx)
                      config
                      storage
                      pull_request_event)
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
                Logs.debug (fun m -> m "%s : NOOP : WORKFLOW_RUN_EVENT" (Brtl_ctx.token ctx));
                Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
            | Ok (Gw.Event.Installation_repositories_event _)
            | Ok (Gw.Event.Workflow_dispatch_event _) ->
                Logs.debug (fun m ->
                    m "%s : NOOP : INSTALLATION_REPOSITORIES_EVENT" (Brtl_ctx.token ctx));
                Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
            | Error (#Terrat_github_webhooks_decoder.err as err) ->
                Prmths.Counter.inc_one Metrics.github_webhook_decode_errors_total;
                Logs.warn (fun m ->
                    m
                      "%s : UNKNOWN_EVENT : %s"
                      (Brtl_ctx.token ctx)
                      (Terrat_github_webhooks_decoder.show_err err));
                Abb.Future.return
                  (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
