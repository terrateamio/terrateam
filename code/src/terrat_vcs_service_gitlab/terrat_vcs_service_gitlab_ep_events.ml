let src = Logs.Src.create "vcs_service_gitlab_ep_events"

module Logs = (val Logs.src_log src : Logs.LOG)

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

let decode ctx = Gitlab_webhooks_decoder.run @@ Brtl_ctx.body ctx

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
      let owner, name =
        match CCString.Split.left ~by:"/" path_with_namespace with
        | Some (owner, name) -> (owner, name)
        | None -> raise (Failure "nyi")
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.insert_installation_repository ())
            (CCInt64.of_int id)
            installation_id
            owner
            name)

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
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute db (Sql.update_installation_to_active ()) installation_id)
      >>= fun () ->
      Abb.Future.return @@ decode ctx
      >>= fun event -> upsert_installation_repo config storage installation_id event
  | (installation_id, _) :: _ ->
      Abb.Future.return @@ decode ctx
      >>= fun event -> upsert_installation_repo config storage installation_id event

let post config storage ctx =
  let headers = Brtl_ctx.Request.headers @@ Brtl_ctx.request ctx in
  match Cohttp.Header.get headers "x-gitlab-token" with
  | Some webhook_secret -> (
      let open Abb.Future.Infix_monad in
      post' config storage webhook_secret ctx
      >>= function
      | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
      | Error (#Gitlab_webhooks_decoder.err as err) ->
          Logs.err (fun m -> m "%a" Gitlab_webhooks_decoder.pp_err err);
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
      | Error `Installation_not_found ->
          Logs.err (fun m -> m "INSTALLATION_NOT_FOUND");
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "%a" Pgsql_pool.pp_err err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  | None ->
      Logs.info (fun m -> m "MISSING_TOKEN_HEADER");
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
