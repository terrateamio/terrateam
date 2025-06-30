let src = Logs.Src.create "vcs_service_gitlab_ep_events"

module Logs = (val Logs.src_log src : Logs.LOG)

module Metrics = struct
  module DefaultHistogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.005; 0.5; 1.0; 5.0; 10.0; 15.0; 20.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "ep_gitlab_events"

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

  let pgsql_pool_errors_total = Terrat_metrics.errors_total ~m:"ep_gitlab_events" ~t:"pgsql_pool"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:"ep_gitlab_events" ~t:"pgsql"
  let gitlab_errors_total = Terrat_metrics.errors_total ~m:"ep_gitlab_events" ~t:"gitlab"

  let gitlab_webhook_decode_errors_total =
    Terrat_metrics.errors_total ~m:"ep_gitlab_events" ~t:"gitlab_webhook_decode"
end

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

  let select_installation_by_webhook_secret () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.bigint
      //
      (* state *)
      Ret.text
      /^ read "select_installation_by_webhook_secret.sql"
      /% Var.text "webhook_secret")

  let update_installation_to_active () =
    Pgsql_io.Typed_sql.(
      sql /^ read "update_installation_to_active.sql" /% Var.bigint "installation_id")

  let insert_installation_repository () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.text "owner"
      /% Var.text "name")
end

module Make (P : Terrat_vcs_provider2_gitlab.S) = struct
  module Evaluator = Terrat_vcs_event_evaluator.Make (P)

  let decode ctx = Gitlab_webhooks_decoder.run @@ Brtl_ctx.body ctx

  let parse_path_with_namespace path_with_namespace =
    match CCString.Split.left ~by:"/" path_with_namespace with
    | Some (owner, name) -> (owner, name)
    | None -> raise (Failure "nyi")

  let upsert_installation_repo config storage installation_id =
    let module E = Gitlab_webhooks.Event in
    let module Pe = Gitlab_webhooks_push_event in
    let module Mre = Gitlab_webhooks_merge_request_event in
    let module Mrce = Gitlab_webhooks_merge_request_comment_event in
    function
    | E.Push_event { Pe.project; _ }
    | E.Merge_request_event { Mre.project; _ }
    | E.Merge_request_comment_event { Mrce.project; _ } ->
        let module P = Gitlab_webhooks_project in
        let { P.id; path_with_namespace; _ } = project in
        let owner, name = parse_path_with_namespace path_with_namespace in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute
              db
              (Sql.insert_installation_repository ())
              (CCInt64.of_int id)
              installation_id
              owner
              name)

  let dispatch_event config storage installation_id ctx =
    let module E = Gitlab_webhooks.Event in
    let module Pr = Gitlab_webhooks_project in
    let module Pe = Gitlab_webhooks_push_event in
    let module Mre = Gitlab_webhooks_merge_request_event in
    let module Mrce = Gitlab_webhooks_merge_request_comment_event in
    let module User = Gitlab_webhooks_user in
    let module Mreoa = Mre.Object_attributes in
    let module Mrceoa = Mrce.Object_attributes in
    let module Mr = Gitlab_webhooks_merge_request in
    function
    | E.Push_event
        {
          Pe.project = { Pr.id = repo_id; path_with_namespace; default_branch; _ };
          ref_;
          user_username;
          _;
        }
      when ref_ = "refs/heads/" ^ default_branch ->
        let owner, name = parse_path_with_namespace path_with_namespace in
        let account = P.Api.Account.make installation_id in
        let repo = P.Api.Repo.make ~id:repo_id ~name ~owner () in
        let user = P.Api.User.make user_username in
        let branch = P.Api.Ref.of_string default_branch in
        Evaluator.run_push ~ctx ~account ~user ~repo ~branch ()
    | E.Push_event _ -> Abb.Future.return (Ok ())
    | E.Merge_request_comment_event
        {
          Mrce.project = { Pr.id = repo_id; path_with_namespace; _ };
          object_attributes =
            { Mrceoa.action = Some "create"; id = Some comment_id; note = Some comment_body; _ };
          user = { User.username; _ };
          merge_request = { Mr.iid = Some pull_request_id; _ };
          _;
        } -> (
        let owner, name = parse_path_with_namespace path_with_namespace in
        let account = P.Api.Account.make installation_id in
        let repo = P.Api.Repo.make ~id:repo_id ~name ~owner () in
        let user = P.Api.User.make username in
        match Terrat_comment.parse comment_body with
        | Ok comment ->
            Evaluator.run_pull_request_comment
              ~ctx
              ~account
              ~user
              ~comment
              ~repo
              ~pull_request_id
              ~comment_id
              ()
        | Error _ -> Abb.Future.return (Ok ()))
    | E.Merge_request_comment_event _ -> Abb.Future.return (Ok ())
    | E.Merge_request_event
        {
          Mre.project = { Pr.id = repo_id; path_with_namespace; _ };
          user = { User.username; _ };
          object_attributes = { Mreoa.action; iid = pull_request_id; _ };
          _;
        } -> (
        let owner, name = parse_path_with_namespace path_with_namespace in
        let account = P.Api.Account.make installation_id in
        let repo = P.Api.Repo.make ~id:repo_id ~name ~owner () in
        let user = P.Api.User.make username in
        match action with
        | "open" | "reopen" ->
            Evaluator.run_pull_request_open ~ctx ~account ~user ~repo ~pull_request_id ()
        | "update" -> Evaluator.run_pull_request_sync ~ctx ~account ~user ~repo ~pull_request_id ()
        | "merge" | "close" ->
            Evaluator.run_pull_request_close ~ctx ~account ~user ~repo ~pull_request_id ()
        | any -> raise (Failure "nyi"))

  let post' config storage webhook_secret ctx =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installation_by_webhook_secret ())
          ~f:(fun id state -> (id, state))
          webhook_secret)
    >>= function
    | [] -> Abb.Future.return (Error `Installation_not_found)
    | (installation_id, "pending") :: _ ->
        Logs.info (fun m ->
            m "%s : EVENT : PING : installation_id=%Ld" (Brtl_ctx.token ctx) installation_id);
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute db (Sql.update_installation_to_active ()) installation_id)
        >>= fun () ->
        Abb.Future.return @@ decode ctx
        >>= fun event ->
        (* We insert the repository here so that during onboarding we can verify
           to the user that the webhook was successfully received *)
        upsert_installation_repo config storage installation_id event
    | (installation_id, _) :: _ ->
        Abb.Future.return @@ decode ctx
        >>= fun event ->
        dispatch_event
          config
          storage
          (CCInt64.to_int installation_id)
          (Evaluator.Ctx.make ~request_id:(Brtl_ctx.token ctx) ~config ~storage ())
          event

  let post config storage ctx =
    let headers = Brtl_ctx.Request.headers @@ Brtl_ctx.request ctx in
    Metrics.DefaultHistogram.time Metrics.events_duration_seconds (fun () ->
        Prmths.Gauge.track_inprogress Metrics.events_concurrent (fun () ->
            match Cohttp.Header.get headers "x-gitlab-token" with
            | Some webhook_secret -> (
                let open Abb.Future.Infix_monad in
                post' config storage webhook_secret ctx
                >>= function
                | Ok () ->
                    Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
                | Error `Error ->
                    Logs.err (fun m -> m "");
                    Abb.Future.return
                      (Brtl_ctx.set_response
                         (Brtl_rspnc.create ~status:`Internal_server_error "")
                         ctx)
                | Error (#Gitlab_webhooks_decoder.err as err) ->
                    Logs.err (fun m -> m "%a" Gitlab_webhooks_decoder.pp_err err);
                    Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
                | Error `Installation_not_found ->
                    Logs.err (fun m -> m "INSTALLATION_NOT_FOUND");
                    Abb.Future.return
                      (Brtl_ctx.set_response
                         (Brtl_rspnc.create ~status:`Internal_server_error "")
                         ctx)
                | Error (#Pgsql_pool.err as err) ->
                    Logs.err (fun m -> m "%a" Pgsql_pool.pp_err err);
                    Abb.Future.return
                      (Brtl_ctx.set_response
                         (Brtl_rspnc.create ~status:`Internal_server_error "")
                         ctx)
                | Error (#Pgsql_io.err as err) ->
                    Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
                    Abb.Future.return
                      (Brtl_ctx.set_response
                         (Brtl_rspnc.create ~status:`Internal_server_error "")
                         ctx))
            | None ->
                Logs.info (fun m -> m "MISSING_TOKEN_HEADER");
                Abb.Future.return
                  (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)))
end
