let src = Logs.Src.create "vcs_service_gitlab_ep_installations"

module Logs = (val Logs.src_log src : Logs.LOG)
module User = Terrat_vcs_service_gitlab_user

module Metrics = struct
  module Psql_query_time = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_linear ~start:0.0 ~interval:0.1 ~count:15
  end)

  let namespace = "terrat_vcs_service_gitlab"
  let subsystem = "ep_installations"

  let psql_query_time =
    let help = "Time for PostgreSQL query" in
    Psql_query_time.v_label ~help ~label_name:"q" ~namespace ~subsystem "psql_query_time"
end

let max_page_size = 100

let replace_where q = function
  | "" -> CCString.replace ~sub:"{{where}}" ~by:"" q
  | where -> CCString.replace ~sub:"{{where}}" ~by:("where " ^ where) q

let set_timeout timeout =
  Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

  let select_user_installations () =
    Pgsql_io.Typed_sql.(sql /^ read "select_user_installations.sql" /% Var.uuid "user_id")

  let upsert_user_installations () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* installation_id *)
      Ret.bigint
      //
      (* name *)
      Ret.text
      //
      (* state *)
      Ret.text
      /^ read "upsert_user_installations.sql"
      /% Var.uuid "user_id"
      /% Var.(array (bigint "installation_ids")))
end

let update_user_installations ~config ~storage ~user () =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Groups = Gitlabc_groups.GetApiV4Groups in
  let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
  Pgsql_pool.with_conn storage ~f:(fun db -> User.Oauth.access_token ~config:vcs_config db user)
  >>= fun token ->
  let client =
    Openapic_abb.create
      ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
      ~user_agent:"Terrateam"
      (`Bearer token)
  in
  Openapic_abb.collect_all
    ~page:Openapic_abb.Page.gitlab
    client
    Groups.(make (Parameters.make ~order_by:"name" ()))
  >>= fun groups ->
  let module G = Gitlabc_components_api_entities_group in
  let group_ids = CCList.map (fun { G.id; _ } -> CCInt64.of_int id) groups in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.upsert_user_installations ())
        ~f:(fun installation_id name state ->
          let module I = Terrat_api_components_installation in
          let module T = Terrat_api_components_tier in
          {
            I.id = CCInt64.to_string installation_id;
            name;
            account_status = state;
            tier = { T.features = { T.Features.num_users_per_month = None }; name = "Unknown" };
            trial_ends_at = None;
          })
        (Terrat_user.id user)
        group_ids)

module List = struct
  let get config storage =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        update_user_installations ~config ~storage ~user ()
        >>= function
        | Ok installations ->
            let module R = Terrat_api_gitlab_installations.List.Responses.OK in
            let body = { R.installations } |> R.to_yojson |> Yojson.Safe.to_string in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error `Error ->
            Logs.err (fun m -> m "ERROR");
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#User.Oauth.access_token_err as err) ->
            Logs.err (fun m -> m "%a" User.Oauth.pp_access_token_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m -> m "%a" Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m ": %a" Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module Webhook = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

    let insert_or_select_installation =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* webhook secret *)
        Ret.text
        //
        (* state *)
        Ret.text
        /^ read "insert_or_select_installation.sql"
        /% Var.bigint "id"
        /% Var.text "name")
  end

  let affirm_is_admin client installation_id user_id =
    let open Abbs_future_combinators.Infix_result_monad in
    let module G = Gitlabc_groups_members.GetApiV4GroupsIdMembersAllUserId in
    Openapic_abb.call
      client
      G.(make (Parameters.make ~id:(CCInt.to_string installation_id) ~user_id))
    >>= fun resp ->
    let module M = Gitlabc_components.API_Entities_Member in
    match Openapi.Response.value resp with
    | `OK { M.access_level; _ } ->
        if access_level >= 50 then Abb.Future.return (Ok ())
        else Abb.Future.return (Error (`Access_level_err access_level))
    | `Not_found -> Abb.Future.return (Error `User_not_found_in_group_err)

  let fetch_group_name client installation_id =
    let open Abbs_future_combinators.Infix_result_monad in
    let module G = Gitlabc_groups.GetApiV4GroupsId in
    Openapic_abb.call client G.(make (Parameters.make ~id:(CCInt.to_string installation_id) ()))
    >>= fun resp ->
    let module Group = Gitlabc_components.API_Entities_GroupDetail in
    let (`OK { Group.name; _ }) = Openapi.Response.value resp in
    Abb.Future.return (Ok name)

  let get' config storage user installation_id webhook_url =
    let open Abbs_future_combinators.Infix_result_monad in
    let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
    let client =
      Openapic_abb.create
        ~user_agent:"Terrateam"
        ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
        (`Bearer (Terrat_config.Gitlab.access_token vcs_config))
    in
    Pgsql_pool.with_conn storage ~f:(fun db -> User.query_user_id db user)
    >>= fun user_id ->
    Abbs_future_combinators.Infix_result_app.(
      (fun name () -> name)
      <$> fetch_group_name client installation_id
      <*> affirm_is_admin client installation_id user_id)
    >>= fun name ->
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.insert_or_select_installation
          ~f:(fun webhook_secret state ->
            let module W = Terrat_api_components.Gitlab_webhook in
            { W.webhook_secret = Some webhook_secret; webhook_url; state })
          (CCInt64.of_int installation_id)
          name)
    >>= function
    | [] -> assert false
    | webhook_secret :: _ -> Abb.Future.return (Ok webhook_secret)

  let get config storage installation_id =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        let c = Terrat_vcs_service_gitlab_provider.Api.Config.config config in
        get'
          config
          storage
          user
          installation_id
          (Printf.sprintf "%s/v1/gitlab/events" (Terrat_config.api_base c))
        >>= function
        | Ok webhook ->
            let body =
              webhook |> Terrat_api_components.Gitlab_webhook.to_yojson |> Yojson.Safe.to_string
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error `User_not_found_in_group_err ->
            Logs.err (fun m -> m "installation_id=%d : USER_NOT_FOUND_IN_GROUP" installation_id);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (`User_not_found_err user) ->
            Logs.err (fun m ->
                m
                  "installation_id=%d : USER_NOT_FOUND : user=%a"
                  installation_id
                  Terrat_user.pp
                  user);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (`Access_level_err access_level) ->
            Logs.err (fun m ->
                m "installation_id=%d : ACCESS_LEVEL : level=%d" installation_id access_level);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m ->
                m "installation_id=%d : %a" installation_id Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "installation_id=%d : %a" installation_id Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "installation_id=%d : %a" installation_id Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module List_repos = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

    let select_installation_repos_page () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        //
        (* installation_id *)
        Ret.bigint
        //
        (* name *)
        Ret.text
        //
        (* updated_at *)
        Ret.text
        //
        (* setup *)
        Ret.boolean
        /^ read "select_installation_repos_page.sql"
        /% Var.uuid "user_id"
        /% Var.bigint "installation_id"
        /% Var.(option (text "prev_name")))
  end

  let columns = Pgsql_pagination.Search.Col.[ create ~vname:"prev_name" ~cname:"name" ]

  module Page = struct
    type cursor = string

    type query = {
      user : Uuidm.t;
      storage : Terrat_storage.t;
      installation_id : int;
      dir : [ `Asc | `Desc ];
      limit : int;
    }

    type t = Terrat_api_components.Installation_repo.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search =
        Pgsql_pagination.Search.(
          create ~page_size:(CCInt.min max_page_size query.limit) ~dir:query.dir columns)
      in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_installation_repos_page ())
            ~f:(fun id installation_id name updated_at setup ->
              {
                Terrat_api_components.Installation_repo.id = CCInt64.to_string id;
                installation_id = CCInt64.to_string installation_id;
                name;
                updated_at;
                setup;
              })
            query.user
            (CCInt64.of_int query.installation_id)
            cursor)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_repos.Responses.OK.(
        { repositories = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_first t =
      let module R = Terrat_api_components.Installation_repo in
      match Pgsql_pagination.results t with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let cursor_of_last t =
      let module R = Terrat_api_components.Installation_repo in
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "%s : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "%s : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get' config storage user installation_id page limit ctx =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        User.enforce_installation_access db user installation_id)
    >>= fun () ->
    let open Abb.Future.Infix_monad in
    let query = Page.{ user = Terrat_user.id user; storage; installation_id; limit; dir = `Asc } in
    Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx)

  let get config storage installation_id page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' config storage user installation_id page limit ctx
        >>= function
        | Ok ctx -> Abb.Future.return (Ok ctx)
        | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module List_dirspaces = struct
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
           (Terrat_files_gitlab_sql.read fname))

    let select_dirspaces where =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        //
        (* dir *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        //
        (* base_ref *)
        Ret.text
        //
        (* branch_ref *)
        Ret.text
        //
        (* completed_at *)
        Ret.(option text)
        //
        (* created_at *)
        Ret.text
        //
        (* run_type *)
        Ret.ud' Terrat_work_manifest3.Step.of_string
        //
        (* state *)
        Ret.text
        //
        (* tag_query *)
        Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        //
        (* pull_number *)
        Ret.(option bigint)
        //
        (* base_branch *)
        Ret.text
        //
        (* owner *)
        Ret.text
        //
        (* repo *)
        Ret.text
        //
        (* run_kind *)
        Ret.text
        //
        (* pull_request_title *)
        Ret.(option text)
        //
        (* branch *)
        Ret.text
        //
        (* username *)
        Ret.(option text)
        //
        (* run_id *)
        Ret.(option text)
        //
        (* environment *)
        Ret.(option text)
        /^ replace_where (read "select_dirspaces_page.sql") where
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.text "tz"
        /% Var.(str_array (text "strings"))
        /% Var.(array (bigint "bigints"))
        /% Var.(str_array (json "json"))
        /% Var.option (Var.text "prev_created_at")
        /% Var.option (Var.text "prev_dir")
        /% Var.option (Var.text "prev_workspace")
        /% Var.option (Var.uuid "prev_id"))
  end

  let tag_map =
    Terrat_sql_of_tag_query.Tag_map.
      [
        ("branch", (String, "branch"));
        ("created_at", (Datetime, "created_at"));
        ("dir", (String, "dir"));
        ("environment", (String, "environment"));
        ("id", (Uuid, "id"));
        ("kind", (String, "kind"));
        ("pr", (Bigint, "pull_number"));
        ("repo", (String, "name"));
        ("state", (String, "state"));
        ("type", (String, "run_type"));
        ("user", (String, "username"));
        ("workspace", (String, "workspace"));
      ]

  let columns =
    Pgsql_pagination.Search.Col.
      [
        create ~vname:"prev_created_at" ~cname:"created_at";
        create ~vname:"prev_dir" ~cname:"dir";
        create ~vname:"prev_workspace" ~cname:"workspace";
        create ~vname:"prev_id" ~cname:"id";
      ]

  module Page = struct
    type cursor = string * string * string * Uuidm.t

    type query = {
      user : Uuidm.t;
      query : Terrat_sql_of_tag_query.t;
      config : Terrat_vcs_service_gitlab_provider.Api.Config.t;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_dirspace.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query return =
      let q = query.query in
      let where = Terrat_sql_of_tag_query.sql q in
      let search =
        Pgsql_pagination.Search.(
          create
            ~page_size:(CCInt.min max_page_size query.limit)
            ~dir:(Terrat_sql_of_tag_query.sort_dir q)
            columns)
      in
      let created_at, dir, workspace, id =
        match cursor with
        | Some (created_at, dir, workspace, id) ->
            (Some created_at, Some dir, Some workspace, Some id)
        | None -> (None, None, None, None)
      in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.tx db ~f:(fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                (set_timeout
                   (Terrat_config.statement_timeout
                   @@ Terrat_vcs_service_gitlab_provider.Api.Config.config query.config))
              >>= fun () ->
              Metrics.Psql_query_time.time (Metrics.psql_query_time "select_dirspaces") (fun () ->
                  return
                    search
                    db
                    (Sql.select_dirspaces where)
                    ~f:(fun
                        id
                        dir
                        workspace
                        base_ref
                        branch_ref
                        completed_at
                        created_at
                        run_type
                        state
                        tag_query
                        pull_number
                        base_branch
                        owner
                        repo
                        run_kind
                        pull_request_title
                        branch
                        user
                        run_id
                        environment
                      ->
                      let module D = Terrat_api_components.Kind_drift in
                      let module I = Terrat_api_components.Kind_index in
                      let module P = Terrat_api_components.Kind_pull_request in
                      let module Ds = Terrat_api_components.Installation_dirspace in
                      {
                        Ds.base_branch;
                        base_ref;
                        branch;
                        branch_ref;
                        completed_at;
                        created_at;
                        dir;
                        environment;
                        id = Uuidm.to_string id;
                        kind =
                          (match (run_kind, pull_number) with
                          | "drift", _ -> Ds.Kind.Kind_drift "drift"
                          | "index", _ -> Ds.Kind.Kind_index "index"
                          | "pr", Some pull_number ->
                              Ds.Kind.Kind_pull_request
                                { P.pull_number = CCInt64.to_int pull_number; pull_request_title }
                          | _ -> assert false);
                        owner;
                        repo;
                        run_id;
                        run_type = Terrat_work_manifest3.Step.to_string run_type;
                        state;
                        tag_query = Terrat_tag_query.to_string tag_query;
                        user;
                        workspace;
                      })
                    query.user
                    (CCInt64.of_int query.installation_id)
                    (Terrat_sql_of_tag_query.timezone q)
                    (Terrat_sql_of_tag_query.strings q)
                    (Terrat_sql_of_tag_query.bigints q)
                    (Terrat_sql_of_tag_query.json q)
                    created_at
                    dir
                    workspace
                    id)))

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_dirspaces.Responses.OK.(
        { dirspaces = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Ds = Terrat_api_components.Installation_dirspace in
      function
      | { Ds.dir; workspace; id; created_at; _ } -> Some [ created_at; dir; workspace; id ]

    let cursor_of_first t =
      match Pgsql_pagination.results t with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let cursor_of_last t =
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | `Statement_timeout ->
          let module Bad_request = Terrat_api_components_bad_request_err in
          Logs.err (fun m -> m "%s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            { Bad_request.id = "STATEMENT_TIMEOUT"; data = None }
            |> Bad_request.to_yojson
            |> Yojson.Safe.to_string
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id query timezone page limit =
    let module Bad_request = Terrat_api_components_bad_request_err in
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            User.enforce_installation_access db user installation_id)
        >>= function
        | Ok () -> (
            match CCOption.map Terrat_tag_query_ast.of_string query with
            | Some (Ok (Some ast)) -> (
                match Terrat_sql_of_tag_query.of_ast ?timezone ~sort_dir:`Desc ~tag_map ast with
                | Ok query ->
                    let query =
                      Page.
                        {
                          user = Terrat_user.id user;
                          query;
                          config;
                          storage;
                          installation_id;
                          limit;
                        }
                    in
                    Paginate.run ?page ~page_param:"page" query ctx
                    >>= fun ctx -> Abb.Future.return (Ok ctx)
                | Error (`Error msg) ->
                    let body =
                      Bad_request.({ id = msg; data = None } |> to_yojson |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error `In_dir_not_supported ->
                    let body =
                      Bad_request.(
                        { id = "IN_DIR_NOT_SUPPORTED"; data = None }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Bad_date_format date) ->
                    let body =
                      Bad_request.(
                        { id = "BAD_DATE_FORMAT"; data = Some date }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Unknown_tag tag) ->
                    let body =
                      Bad_request.(
                        { id = "UNKNOWN_TAG"; data = Some tag }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                )
            | Some (Ok None) | None ->
                let query =
                  Page.
                    {
                      user = Terrat_user.id user;
                      query = Terrat_sql_of_tag_query.empty ?timezone ~sort_dir:`Desc ();
                      config;
                      storage;
                      installation_id;
                      limit;
                    }
                in
                Paginate.run ?page ~page_param:"page" query ctx
                >>= fun ctx -> Abb.Future.return (Ok ctx)
            | Some (Error (`Tag_query_error (_, err))) ->
                let body =
                  Bad_request.(
                    { id = "PARSE_ERROR"; data = Some err } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
        | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module List_work_manifest_outputs = struct
  module T = Terrat_api_components.Installation_workflow_step_output

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
           (Terrat_files_gitlab_sql.read fname))

    let scope =
      let module T = Terrat_api_components.Workflow_step_output_scope in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map T.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let payload =
      let module T = T.Payload in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map T.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let select_outputs where =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* created_at *)
        Ret.text
        //
        (* idx *)
        Ret.smallint
        //
        (* ignore_errors *)
        Ret.boolean
        //
        (* payload *)
        Ret.(option (ud' payload))
        //
        (* scope *)
        Ret.ud' scope
        //
        (* step *)
        Ret.text
        //
        (* status *)
        Ret.text
        /^ replace_where (read "select_workflow_outputs_page.sql") where
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.uuid "work_manifest_id"
        /% Var.(str_array (text "strings"))
        /% Var.(array (bigint "bigints"))
        /% Var.(array (integer "ints"))
        /% Var.(str_array (json "json"))
        /% Var.option (Var.smallint "prev_idx")
        /% Var.boolean "lite")
  end

  let tag_map =
    Terrat_sql_of_tag_query.Tag_map.
      [
        ("dir", (Json_obj "dir", "scope"));
        ("flow", (Json_obj "flow", "scope"));
        ("idx", (Int, "idx"));
        ("ignore_errors", (Bool, "ignore_errors"));
        ("scope", (Json_obj "type", "scope"));
        ("state", (String, "state"));
        ("step", (String, "step"));
        ("subflow", (Json_obj "subflow", "scope"));
        ("workspace", (Json_obj "workspace", "scope"));
      ]

  let columns = Pgsql_pagination.Search.Col.[ create ~vname:"prev_idx" ~cname:"idx" ]

  module Page = struct
    type cursor = int

    type query = {
      config : Terrat_vcs_service_gitlab_provider.Api.Config.t;
      installation_id : int;
      limit : int;
      query : Terrat_sql_of_tag_query.t;
      storage : Terrat_storage.t;
      user : Uuidm.t;
      work_manifest_id : Uuidm.t;
      lite : bool;
    }

    type t = T.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query return =
      let q = query.query in
      let where = Terrat_sql_of_tag_query.sql q in
      let search =
        Pgsql_pagination.Search.(
          create
            ~page_size:(CCInt.min max_page_size query.limit)
            ~dir:(Terrat_sql_of_tag_query.sort_dir q)
            columns)
      in
      let idx = cursor in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.tx db ~f:(fun () ->
              Metrics.Psql_query_time.time (Metrics.psql_query_time "select_outputs") (fun () ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    (set_timeout
                       (Terrat_config.statement_timeout
                       @@ Terrat_vcs_service_gitlab_provider.Api.Config.config query.config))
                  >>= fun () ->
                  return
                    search
                    db
                    (Sql.select_outputs where)
                    ~f:(fun created_at idx ignore_errors payload scope step state ->
                      { T.created_at; idx; ignore_errors; payload; scope; state; step })
                    query.user
                    (CCInt64.of_int query.installation_id)
                    query.work_manifest_id
                    (Terrat_sql_of_tag_query.strings q)
                    (Terrat_sql_of_tag_query.bigints q)
                    (Terrat_sql_of_tag_query.ints q)
                    (Terrat_sql_of_tag_query.json q)
                    idx
                    query.lite)))

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.Get_work_manifest_outputs.Responses.OK.(
        { steps = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el el = [ CCInt.to_string el.T.idx ]

    let cursor_of_first t =
      CCOption.map cursor_of_el (CCOption.of_list (Pgsql_pagination.results t))

    let cursor_of_last t =
      CCOption.map cursor_of_el (CCOption.of_list (CCList.rev (Pgsql_pagination.results t)))

    let has_another_page = Pgsql_pagination.has_next_page

    let rspnc_of_err ~token = function
      | `Statement_timeout ->
          let module Bad_request = Terrat_api_components_bad_request_err in
          Logs.err (fun m -> m "%s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            Bad_request.(
              { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id work_manifest_id query timezone page limit lite =
    let module Bad_request = Terrat_api_components_bad_request_err in
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            User.enforce_installation_access db user installation_id)
        >>= function
        | Ok () -> (
            match CCOption.map Terrat_tag_query_ast.of_string query with
            | Some (Ok (Some ast)) -> (
                match Terrat_sql_of_tag_query.of_ast ?timezone ~sort_dir:`Asc ~tag_map ast with
                | Ok query ->
                    let query =
                      {
                        Page.config;
                        installation_id;
                        limit;
                        query;
                        storage;
                        user = Terrat_user.id user;
                        work_manifest_id;
                        lite;
                      }
                    in
                    Paginate.run ?page ~page_param:"page" query ctx
                    >>= fun ctx -> Abb.Future.return (Ok ctx)
                | Error (`Error msg) ->
                    let body =
                      Bad_request.({ id = msg; data = None } |> to_yojson |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error `In_dir_not_supported ->
                    let body =
                      Bad_request.(
                        { id = "IN_DIR_NOT_SUPPORTED"; data = None }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Bad_date_format date) ->
                    let body =
                      Bad_request.(
                        { id = "BAD_DATE_FORMAT"; data = Some date }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Unknown_tag tag) ->
                    let body =
                      Bad_request.(
                        { id = "UNKNOWN_TAG"; data = Some tag }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                )
            | Some (Ok None) | None ->
                let query =
                  {
                    Page.config;
                    installation_id;
                    limit;
                    query = Terrat_sql_of_tag_query.empty ?timezone ~sort_dir:`Asc ();
                    storage;
                    user = Terrat_user.id user;
                    work_manifest_id;
                    lite;
                  }
                in
                Paginate.run ?page ~page_param:"page" query ctx
                >>= fun ctx -> Abb.Future.return (Ok ctx)
            | Some (Error (`Tag_query_error (_, err))) ->
                let body =
                  Bad_request.(
                    { id = "PARSE_ERROR"; data = Some err } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
        | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module List_work_manifests = struct
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
           (Terrat_files_gitlab_sql.read fname))

    let dirspaces =
      let module T = struct
        type t = Terrat_api_components.Work_manifest_dirspace.t list [@@deriving yojson]
      end in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map T.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let select_work_manifests where =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        //
        (* base_hash *)
        Ret.text
        //
        (* branch_ref *)
        Ret.text
        //
        (* completed_at *)
        Ret.(option text)
        //
        (* created_at *)
        Ret.text
        //
        (* run_type *)
        Ret.ud' Terrat_work_manifest3.Step.of_string
        //
        (* state *)
        Ret.ud' Terrat_work_manifest3.State.of_string
        //
        (* tag_query *)
        Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        //
        (* pull_number *)
        Ret.(option bigint)
        //
        (* base_branch *)
        Ret.text
        //
        (* owner *)
        Ret.text
        //
        (* repo *)
        Ret.text
        //
        (* run_kind *)
        Ret.text
        //
        (* dirspaces *)
        Ret.(option (ud' dirspaces))
        //
        (* pull_request_title *)
        Ret.(option text)
        //
        (* branch *)
        Ret.text
        //
        (* username *)
        Ret.(option text)
        //
        (* run_id *)
        Ret.(option text)
        //
        (* environment *)
        Ret.(option text)
        /^ replace_where (read "select_work_manifests_page.sql") where
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.text "tz"
        /% Var.(str_array (text "strings"))
        /% Var.(array (bigint "bigints"))
        /% Var.(str_array (json "json"))
        /% Var.option (Var.text "prev_created_at")
        /% Var.option (Var.uuid "prev_id"))
  end

  let tag_map =
    Terrat_sql_of_tag_query.Tag_map.
      [
        ("branch", (String, "branch"));
        ("created_at", (Datetime, "created_at"));
        ("dir", (Json_array "dir", "dirspaces"));
        ("environment", (String, "environment"));
        ("id", (Uuid, "id"));
        ("kind", (String, "kind"));
        ("pr", (Bigint, "pull_number"));
        ("repo", (String, "name"));
        ("state", (String, "state"));
        ("type", (String, "run_type"));
        ("user", (String, "username"));
        ("workspace", (Json_array "workspace", "dirspaces"));
      ]

  let columns =
    Pgsql_pagination.Search.Col.
      [ create ~vname:"prev_created_at" ~cname:"created_at"; create ~vname:"prev_id" ~cname:"id" ]

  module Page = struct
    type cursor = string * Uuidm.t

    type query = {
      user : Uuidm.t;
      query : Terrat_sql_of_tag_query.t;
      config : Terrat_vcs_service_gitlab_provider.Api.Config.t;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_work_manifest.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query return =
      let q = query.query in
      let where = Terrat_sql_of_tag_query.sql q in
      let search =
        Pgsql_pagination.Search.(
          create
            ~page_size:(CCInt.min max_page_size query.limit)
            ~dir:(Terrat_sql_of_tag_query.sort_dir q)
            columns)
      in
      let created_at, id =
        match cursor with
        | Some (created_at, id) -> (Some created_at, Some id)
        | None -> (None, None)
      in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.tx db ~f:(fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                (set_timeout
                   (Terrat_config.statement_timeout
                   @@ Terrat_vcs_service_gitlab_provider.Api.Config.config query.config))
              >>= fun () ->
              Metrics.Psql_query_time.time
                (Metrics.psql_query_time "select_work_manifests")
                (fun () ->
                  return
                    search
                    db
                    (Sql.select_work_manifests where)
                    ~f:(fun
                        id
                        base_ref
                        branch_ref
                        completed_at
                        created_at
                        run_type
                        state
                        tag_query
                        pull_number
                        base_branch
                        owner
                        repo
                        run_kind
                        dirspaces
                        pull_request_title
                        branch
                        user
                        run_id
                        environment
                      ->
                      let module D = Terrat_api_components.Kind_drift in
                      let module I = Terrat_api_components.Kind_index in
                      let module P = Terrat_api_components.Kind_pull_request in
                      let module Wm = Terrat_api_components.Installation_work_manifest in
                      {
                        Wm.base_branch;
                        base_ref;
                        branch;
                        branch_ref;
                        completed_at;
                        created_at;
                        dirspaces = CCOption.get_or ~default:[] dirspaces;
                        environment;
                        id = Uuidm.to_string id;
                        kind =
                          (match (run_kind, pull_number) with
                          | "drift", _ -> Wm.Kind.Kind_drift "drift"
                          | "index", _ -> Wm.Kind.Kind_index "index"
                          | "pr", Some pull_number ->
                              Wm.Kind.Kind_pull_request
                                { P.pull_number = CCInt64.to_int pull_number; pull_request_title }
                          | _ -> assert false);
                        owner;
                        repo;
                        run_id;
                        run_type = Terrat_work_manifest3.Step.to_string run_type;
                        state = Terrat_work_manifest3.State.to_string state;
                        tag_query = Terrat_tag_query.to_string tag_query;
                        user;
                      })
                    query.user
                    (CCInt64.of_int query.installation_id)
                    (Terrat_sql_of_tag_query.timezone q)
                    (Terrat_sql_of_tag_query.strings q)
                    (Terrat_sql_of_tag_query.bigints q)
                    (Terrat_sql_of_tag_query.json q)
                    created_at
                    id)))

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_work_manifests.Responses.OK.(
        { work_manifests = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Wm = Terrat_api_components.Installation_work_manifest in
      function
      | { Wm.id; created_at; _ } -> Some [ created_at; id ]

    let cursor_of_first t =
      match Pgsql_pagination.results t with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let cursor_of_last t =
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | `Statement_timeout ->
          let module Bad_request = Terrat_api_components_bad_request_err in
          Logs.err (fun m -> m "%s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            Bad_request.(
              { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "%s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id query timezone page limit =
    let module Bad_request = Terrat_api_components_bad_request_err in
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            User.enforce_installation_access db user installation_id)
        >>= function
        | Ok () -> (
            match CCOption.map Terrat_tag_query_ast.of_string query with
            | Some (Ok (Some ast)) -> (
                match Terrat_sql_of_tag_query.of_ast ?timezone ~sort_dir:`Desc ~tag_map ast with
                | Ok query ->
                    let query =
                      Page.
                        {
                          user = Terrat_user.id user;
                          query;
                          config;
                          storage;
                          installation_id;
                          limit;
                        }
                    in
                    Paginate.run ?page ~page_param:"page" query ctx
                    >>= fun ctx -> Abb.Future.return (Ok ctx)
                | Error (`Error msg) ->
                    let body =
                      Bad_request.({ id = msg; data = None } |> to_yojson |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error `In_dir_not_supported ->
                    let body =
                      Bad_request.(
                        { id = "IN_DIR_NOT_SUPPORTED"; data = None }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Bad_date_format date) ->
                    let body =
                      Bad_request.(
                        { id = "BAD_DATE_FORMAT"; data = Some date }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                | Error (`Unknown_tag tag) ->
                    let body =
                      Bad_request.(
                        { id = "UNKNOWN_TAG"; data = Some tag }
                        |> to_yojson
                        |> Yojson.Safe.to_string)
                    in
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx))
                )
            | Some (Ok None) | None ->
                let query =
                  Page.
                    {
                      user = Terrat_user.id user;
                      query = Terrat_sql_of_tag_query.empty ?timezone ~sort_dir:`Desc ();
                      config;
                      storage;
                      installation_id;
                      limit;
                    }
                in
                Paginate.run ?page ~page_param:"page" query ctx
                >>= fun ctx -> Abb.Future.return (Ok ctx)
            | Some (Error (`Tag_query_error (_, err))) ->
                let body =
                  Bad_request.(
                    { id = "PARSE_ERROR"; data = Some err } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
        | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
