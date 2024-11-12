let max_page_size = 100

let replace_where q = function
  | "" -> CCString.replace ~sub:"{{where}}" ~by:"" q
  | where -> CCString.replace ~sub:"{{where}}" ~by:("where " ^ where) q

let set_timeout timeout =
  Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

module Work_manifests = struct
  module Outputs = struct
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
             (Terrat_files_sql.read fname))

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
          // (* created_at *) Ret.text
          // (* idx *) Ret.smallint
          // (* ignore_errors *) Ret.boolean
          // (* payload *) Ret.ud' payload
          // (* scope *) Ret.ud' scope
          // (* step *) Ret.text
          // (* status *) Ret.text
          /^ replace_where (read "select_github_workflow_outputs_page.sql") where
          /% Var.uuid "user"
          /% Var.bigint "installation_id"
          /% Var.uuid "work_manifest_id"
          /% Var.(str_array (text "strings"))
          /% Var.(array (bigint "bigints"))
          /% Var.(str_array (json "json"))
          /% Var.option (Var.smallint "prev_idx"))
    end

    let tag_map =
      Terrat_sql_of_tag_query.Tag_map.
        [
          ("dir", (Json_obj "dir", "scope"));
          ("flow", (Json_obj "flow", "scope"));
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
        config : Terrat_config.t;
        installation_id : int;
        limit : int;
        query : Terrat_sql_of_tag_query.t;
        storage : Terrat_storage.t;
        user : Uuidm.t;
        work_manifest_id : Uuidm.t;
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
                Pgsql_io.Prepared_stmt.execute
                  db
                  (set_timeout (Terrat_config.statement_timeout query.config))
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
                  (Terrat_sql_of_tag_query.json q)
                  idx))

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
            let module Bad_request =
              Terrat_api_installations.List_work_manifests.Responses.Bad_request
            in
            Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : STATEMENT_TIMEOUT" token);
            let body =
              Bad_request.(
                { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
            in
            Brtl_rspnc.create ~status:`Bad_request body
        | #Pgsql_pool.err as err ->
            Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
            Brtl_rspnc.create ~status:`Internal_server_error ""
        | #Pgsql_io.err as err ->
            Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
            Brtl_rspnc.create ~status:`Internal_server_error ""
    end

    module Paginate = Brtl_ep_paginate.Make (Page)

    let get config storage installation_id work_manifest_id query timezone page limit =
      let module Bad_request =
        Terrat_api_installations.Get_work_manifest_outputs.Responses.Bad_request
      in
      Brtl_ep.run_result ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ctx
          >>= fun user ->
          Terrat_user.enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
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
                      { id = "UNKNOWN_TAG"; data = Some tag } |> to_yojson |> Yojson.Safe.to_string)
                  in
                  Abb.Future.return
                    (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
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
        // (* id *) Ret.uuid
        // (* base_hash *) Ret.text
        // (* branch_ref *) Ret.text
        // (* completed_at *) Ret.(option text)
        // (* created_at *) Ret.text
        // (* run_type *) Ret.ud' Terrat_work_manifest3.Step.of_string
        // (* state *) Ret.ud' Terrat_work_manifest3.State.of_string
        // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        // (* pull_number *) Ret.(option bigint)
        // (* base_branch *) Ret.text
        // (* owner *) Ret.text
        // (* repo *) Ret.text
        // (* run_kind *) Ret.text
        // (* dirspaces *) Ret.(option (ud' dirspaces))
        // (* pull_request_title *) Ret.(option text)
        // (* branch *) Ret.text
        // (* username *) Ret.(option text)
        // (* run_id *) Ret.(option text)
        // (* environment *) Ret.(option text)
        /^ replace_where (read "select_github_work_manifests_page.sql") where
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
      config : Terrat_config.t;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_work_manifest.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
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
                (set_timeout (Terrat_config.statement_timeout query.config))
              >>= fun () ->
              f
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
                id))

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
          let module Bad_request =
            Terrat_api_installations.List_work_manifests.Responses.Bad_request
          in
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            Bad_request.(
              { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id query timezone page limit =
    let module Bad_request = Terrat_api_installations.List_work_manifests.Responses.Bad_request in
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        match CCOption.map Terrat_tag_query_ast.of_string query with
        | Some (Ok (Some ast)) -> (
            match Terrat_sql_of_tag_query.of_ast ?timezone ~sort_dir:`Desc ~tag_map ast with
            | Ok query ->
                let query =
                  Page.
                    { user = Terrat_user.id user; query; config; storage; installation_id; limit }
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
                    { id = "UNKNOWN_TAG"; data = Some tag } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
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
end

module Dirspaces = struct
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

    let select_dirspaces where =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.uuid
        // (* dir *) Ret.text
        // (* workspace *) Ret.text
        // (* base_ref *) Ret.text
        // (* branch_ref *) Ret.text
        // (* completed_at *) Ret.(option text)
        // (* created_at *) Ret.text
        // (* run_type *) Ret.ud' Terrat_work_manifest3.Step.of_string
        // (* state *) Ret.text
        // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        // (* pull_number *) Ret.(option bigint)
        // (* base_branch *) Ret.text
        // (* owner *) Ret.text
        // (* repo *) Ret.text
        // (* run_kind *) Ret.text
        // (* pull_request_title *) Ret.(option text)
        // (* branch *) Ret.text
        // (* username *) Ret.(option text)
        // (* run_id *) Ret.(option text)
        // (* environment *) Ret.(option text)
        /^ replace_where (read "select_github_dirspaces_page.sql") where
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
      config : Terrat_config.t;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_dirspace.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
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
                (set_timeout (Terrat_config.statement_timeout query.config))
              >>= fun () ->
              f
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
                id))

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
          let module Bad_request = Terrat_api_installations.List_dirspaces.Responses.Bad_request in
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            Bad_request.(
              { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id query timezone page limit =
    let module Bad_request = Terrat_api_installations.List_dirspaces.Responses.Bad_request in
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        match CCOption.map Terrat_tag_query_ast.of_string query with
        | Some (Ok (Some ast)) -> (
            match Terrat_sql_of_tag_query.of_ast ?timezone ~sort_dir:`Desc ~tag_map ast with
            | Ok query ->
                let query =
                  Page.
                    { user = Terrat_user.id user; query; config; storage; installation_id; limit }
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
                    { id = "UNKNOWN_TAG"; data = Some tag } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
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
end

module Pull_requests = struct
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

    let select_pull_requests () =
      Pgsql_io.Typed_sql.(
        sql
        // (* base_branch *) Ret.text
        // (* base_sha *) Ret.text
        // (* branch *) Ret.text
        // (* latest_work_manifest_run_at *) Ret.(option text)
        // (* merged_at *) Ret.(option text)
        // (* merged_sha *) Ret.(option text)
        // (*name *) Ret.text
        // (* owner *) Ret.text
        // (* pull_number *) Ret.bigint
        // (* repository *) Ret.bigint
        // (* sha *) Ret.text
        // (* state *) Ret.text
        // (* title *) Ret.(option text)
        // (* username *) Ret.(option text)
        /^ read "select_github_pull_requests_page.sql"
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.(option (bigint "pull_number"))
        /% Var.option (Var.bigint "prev_pull_number"))
  end

  let columns =
    Pgsql_pagination.Search.Col.[ create ~vname:"prev_pull_number" ~cname:"pull_number" ]

  module Page = struct
    type cursor = int64

    type query = {
      user : Uuidm.t;
      pull_request : int option;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_pull_request.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search =
        Pgsql_pagination.Search.(
          create ~page_size:(CCInt.min max_page_size query.limit) ~dir:`Desc columns)
      in
      let pull_number = cursor in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_pull_requests ())
            ~f:(fun
                base_branch
                base_sha
                branch
                latest_work_manifest_run_at
                merged_at
                merged_sha
                name
                owner
                pull_number
                repository
                sha
                state
                title
                user
              ->
              let module Pr = Terrat_api_components.Installation_pull_request in
              Pr.
                {
                  base_branch;
                  base_sha;
                  branch;
                  latest_work_manifest_run_at;
                  merged_at;
                  merged_sha;
                  name;
                  owner;
                  pull_number = CCInt64.to_int pull_number;
                  repository = CCInt64.to_int repository;
                  sha;
                  state;
                  title;
                  user;
                })
            query.user
            (CCInt64.of_int query.installation_id)
            (CCOption.map CCInt64.of_int query.pull_request)
            pull_number)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_pull_requests.Responses.OK.(
        { pull_requests = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Pr = Terrat_api_components.Installation_pull_request in
      function
      | Pr.{ pull_number; _ } -> Some [ CCInt.to_string pull_number ]

    let cursor_of_first t =
      match Pgsql_pagination.results t with
      | [] -> None
      | pr :: _ -> cursor_of_el pr

    let cursor_of_last t =
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | pr :: _ -> cursor_of_el pr

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id pr_opt page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.
            { user = Terrat_user.id user; pull_request = pr_opt; storage; installation_id; limit }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))
end

module Repos = struct
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

    let select_installation_repos_page () =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.bigint
        // (* installation_id *) Ret.bigint
        // (* name *) Ret.text
        // (* updated_at *) Ret.text
        // (* setup *) Ret.boolean
        /^ read "select_github_installation_repos_page.sql"
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
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.{ user = Terrat_user.id user; storage; installation_id; limit; dir = `Asc }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))

  module Refresh = struct
    let post config storage installation_id =
      Brtl_ep.run_result ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ctx
          >>= fun user ->
          Terrat_user.enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          Terrat_github_installation.refresh_repos'
            ~request_id:(Brtl_ctx.token ctx)
            ~config
            ~storage
            (Terrat_github_installation.Id.make installation_id)
          >>= function
          | Ok task ->
              let id = Uuidm.to_string (Terrat_task.id task) in
              let body =
                Terrat_api_installations.Repo_refresh.Responses.OK.(
                  { id } |> to_yojson |> Yojson.Safe.to_string)
              in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m
                    "INSTALLATION : %s : REFRESH_REPOS : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_pool.pp_err
                    err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m
                    "INSTALLATION : %s : REFRESH_REPOS : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_io.pp_err
                    err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end
end
