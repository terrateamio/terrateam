let src = Logs.Src.create "vcs_service_gitlab_ep_mql"

module Logs = (val Logs.src_log src : Logs.LOG)
module Er = Terrat_api_components.Error_response

let default_limit = 20
let max_limit = 1000

let set_timeout timeout =
  Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

module Sql = struct
  let select_page q =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* row *)
      Ret.jsonb
      /^ CCString.replace ~sub:"{{q}}" ~by:q [%blob "sql/select_mql_page.sql"]
      /% Var.uuid "user_id"
      /% Var.bigint "installation_id"
      /% Var.(str_array (text "texts"))
      /% Var.(str_array (json "json"))
      /% Var.(array (smallint "smallints"))
      /% Var.(array (integer "integers"))
      /% Var.(array (bigint "bigints"))
      /% Var.(array (double "floats")))

  (* Like [select_page] but against the [select_mql_page_admin.sql] template,
     which is installation-scoped only (no [$user_id] filter). Used when the
     caller holds the [Mql_admin] capability. *)
  let select_page_admin q =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* row *)
      Ret.jsonb
      /^ CCString.replace ~sub:"{{q}}" ~by:q [%blob "sql/select_mql_page_admin.sql"]
      /% Var.bigint "installation_id"
      /% Var.(str_array (text "texts"))
      /% Var.(str_array (json "json"))
      /% Var.(array (smallint "smallints"))
      /% Var.(array (integer "integers"))
      /% Var.(array (bigint "bigints"))
      /% Var.(array (double "floats")))

  let set_timezone () = Pgsql_io.Typed_sql.(sql /^ "set local timezone = $tz" /% Var.text "tz")
end

(* The MQL table allow-list.

   SECURITY -- two coupled lists: every table named here MUST also have a
   matching installation-scoped CTE in [sql/select_mql_page.sql]. A query may
   only name tables that appear here; inside [select_mql_page.sql] each such
   name resolves to a CTE that is filtered to the caller's installation. If a
   table is added here without a corresponding CTE, the name resolves to the
   REAL, UNSCOPED table -> cross-installation data exposure. Keep this list a
   subset of the CTE names defined in [select_mql_page.sql].

   The MQL-visible names are clean (e.g. [work_manifests]); each one maps to the
   GitLab-specific table behind the scenes (e.g. [gitlab_work_manifests]). *)
let schema =
  Mql_to_pgsql.Schema.(
    make
      [
        Table.make
          ~name:"repositories"
          Column.
            [
              make ~name:"id" ~type_:Type_.Bigint ();
              make ~name:"installation_id" ~type_:Type_.Bigint ();
              make ~name:"name" ~type_:Type_.Text ();
              make ~name:"owner" ~type_:Type_.Text ();
              make ~name:"updated_at" ~type_:Type_.Timestamptz ();
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
              make ~name:"setup" ~type_:Type_.Bool ();
            ];
        Table.make
          ~name:"pull_requests"
          Column.
            [
              make ~name:"base_branch" ~type_:Type_.Text ();
              make ~name:"base_sha" ~type_:Type_.Text ();
              make ~name:"branch" ~type_:Type_.Text ();
              make ~name:"pull_number" ~type_:Type_.Bigint ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"state" ~type_:Type_.Text ();
              make ~name:"merged_sha" ~type_:Type_.Text ();
              make ~name:"merged_at" ~type_:Type_.Timestamptz ();
              make ~name:"title" ~type_:Type_.Text ();
              make ~name:"username" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"work_manifests"
          Column.
            [
              make ~name:"id" ~type_:Type_.Uuid ();
              make ~name:"base_sha" ~type_:Type_.Text ();
              make ~name:"completed_at" ~type_:Type_.Timestamptz ();
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
              make ~name:"pull_number" ~type_:Type_.Bigint ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"run_id" ~type_:Type_.Text ();
              make ~name:"run_type" ~type_:Type_.Text ();
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"state" ~type_:Type_.Text ();
              make ~name:"tag_query" ~type_:Type_.Text ();
              make ~name:"username" ~type_:Type_.Text ();
              make ~name:"dirspaces" ~type_:Type_.Jsonb ();
              make ~name:"run_kind" ~type_:Type_.Text ();
              make ~name:"environment" ~type_:Type_.Text ();
              make ~name:"runs_on" ~type_:Type_.Jsonb ();
              make ~name:"installation_id" ~type_:Type_.Bigint ();
              make ~name:"repo_owner" ~type_:Type_.Text ();
              make ~name:"repo_name" ~type_:Type_.Text ();
              make ~name:"branch" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"gates"
          Column.
            [
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
              make ~name:"dir" ~type_:Type_.Text ();
              make ~name:"gate" ~type_:Type_.Jsonb ();
              make ~name:"pull_number" ~type_:Type_.Bigint ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"name" ~type_:Type_.Text ();
              make ~name:"workspace" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"gate_approvals"
          Column.
            [
              make ~name:"approver" ~type_:Type_.Text ();
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
              make ~name:"pull_number" ~type_:Type_.Bigint ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"sha" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"drift_schedules"
          Column.
            [
              make ~name:"reconcile" ~type_:Type_.Bool ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"schedule" ~type_:Type_.Text ();
              make ~name:"updated_at" ~type_:Type_.Timestamptz ();
              make ~name:"tag_query" ~type_:Type_.Text ();
              make ~name:"name" ~type_:Type_.Text ();
              make ~name:"branch" ~type_:Type_.Text ();
              make ~name:"last_tried_at" ~type_:Type_.Timestamptz ();
            ];
        Table.make
          ~name:"change_dirspaces"
          Column.
            [
              make ~name:"base_sha" ~type_:Type_.Text ();
              make ~name:"path" ~type_:Type_.Text ();
              make ~name:"repository" ~type_:Type_.Bigint ();
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"workspace" ~type_:Type_.Text ();
              make ~name:"lock_policy" ~type_:Type_.Text ();
              make ~name:"branch_target" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"repo_trees"
          Column.
            [
              make ~name:"installation_id" ~type_:Type_.Bigint ();
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
              make ~name:"path" ~type_:Type_.Text ();
              make ~name:"changed" ~type_:Type_.Bool ();
              make ~name:"id" ~type_:Type_.Text ();
            ];
        Table.make
          ~name:"code_indexes"
          Column.
            [
              make ~name:"sha" ~type_:Type_.Text ();
              make ~name:"installation_id" ~type_:Type_.Bigint ();
              make ~name:"index" ~type_:Type_.Jsonb ();
              make ~name:"created_at" ~type_:Type_.Timestamptz ();
            ];
      ])

let encode_link rel uri = Printf.sprintf "<%s>; rel=\"%s\"" (Uri.to_string uri) rel

let merge_uri_base uri_base uri =
  Uri.with_query
    (Uri.with_path uri_base (CCString.rdrop_while (( = ) '/') (Uri.path uri_base) ^ Uri.path uri))
    (Uri.query uri)

let update_page_param uri cursor =
  uri
  |> CCFun.flip Uri.remove_query_param "page"
  |> fun uri -> Uri.add_query_param' uri ("page", cursor)

let mk_pagination_headers (prev, next) ctx =
  let merged_uri_base = merge_uri_base (Brtl_ctx.uri_base ctx) (Brtl_ctx.uri ctx) in
  let next_uri = CCOption.map (update_page_param merged_uri_base) next in
  let prev_uri = CCOption.map (update_page_param merged_uri_base) prev in
  let link =
    CCString.concat
      ", "
      (CCOption.to_list (CCOption.map (encode_link "next") next_uri)
      @ CCOption.to_list (CCOption.map (encode_link "prev") prev_uri))
  in
  let headers = Cohttp.Header.of_list [ ("link", link) ] in
  headers

(* Parse the page cursor (a JSON-encoded [Mql_to_pgsql.Page.t]) from the query
   string. [None] means no page was requested. *)
let parse_page = function
  | None -> Ok None
  | Some s -> (
      match Mql_to_pgsql.Page.of_yojson (Yojson.Safe.from_string s) with
      | Ok p -> Ok (Some p)
      | Error _ -> Error `Page_err
      | exception _ -> Error `Page_err)

(* Parse the MQL query string, apply the requested page (if any), and compile
   the result to a pgsql query. Returns the compiled query together with the
   effective row limit the caller asked for. *)
let build_query q page =
  let open Abbs_future_combinators.Infix_result_monad in
  Abb.Future.return @@ Mql.Ast.of_string q
  >>= fun ast ->
  Abb.Future.return
  @@ CCOption.map_or ~default:(Ok ast) (fun page -> Mql_to_pgsql.apply_page page ast) page
  >>= fun ast ->
  let limit = CCInt.min max_limit @@ CCOption.get_or ~default:default_limit @@ Mql.Ast.limit ast in
  (* Ensure that we query 1 more than the user asked for, that way we can know
     by the extra row item that there is another page. *)
  Abb.Future.return
  @@ Mql_to_pgsql.of_mql ~max_limit:(limit + 1) ~schema
  @@ Mql.Ast.set_limit (limit + 1) ast
  >>= fun query -> Abb.Future.return (Ok (query, limit))

(* Execute the compiled query inside a transaction, applying the configured
   statement timeout and, when provided, the caller's timezone. Returns the raw
   rows fetched from the database, scoped to [user] and [installation_id]. *)
let execute_query ~admin config storage user installation_id tz query =
  let open Abbs_future_combinators.Infix_result_monad in
  let statement_timeout =
    Terrat_config.statement_timeout @@ Terrat_vcs_service_gitlab_provider.Api.Config.config config
  in
  let query_str = Mql.Ast.to_string @@ Mql_to_pgsql.query query in
  let texts = CCVector.to_list @@ Mql_to_pgsql.texts query in
  let json = List.map Yojson.Safe.from_string (CCVector.to_list @@ Mql_to_pgsql.json query) in
  let smallints = CCVector.to_list @@ Mql_to_pgsql.smallints query in
  let integers = CCVector.to_list @@ Mql_to_pgsql.integers query in
  let bigints = CCVector.to_list @@ Mql_to_pgsql.bigints query in
  let floats = CCVector.to_list @@ Mql_to_pgsql.floats query in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.execute db (set_timeout statement_timeout)
          >>= fun () ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun tz -> Pgsql_io.Prepared_stmt.execute db (Sql.set_timezone ()) tz)
            (CCOption.to_list tz)
          >>= fun () ->
          if admin then
            (* The [Mql_admin] capability bypasses the per-user installation
               scoping: the admin template filters by installation only. *)
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_page_admin query_str)
              ~f:CCFun.id
              (CCInt64.of_int installation_id)
              texts
              json
              smallints
              integers
              bigints
              floats
          else
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_page query_str)
              ~f:CCFun.id
              user
              (CCInt64.of_int installation_id)
              texts
              json
              smallints
              integers
              bigints
              floats))

(* The query fetches one row more than requested, so an extra ("excessive") row
   signals that a further page exists. Drop the cursor row when paginating and
   the sentinel extra row, and restore natural order when paging backwards. *)
let trim_rows ~limit ~page ~excessive_rows rows =
  let page_dir =
    CCOption.map_or
      ~default:Mql_to_pgsql.Page.Affirm
      (fun { Mql_to_pgsql.Page.dir; cursor = _ } -> dir)
      page
  in
  let rows = if CCOption.is_some page then CCList.drop 1 rows else rows in
  match page_dir with
  | Mql_to_pgsql.Page.Affirm when excessive_rows -> CCList.take limit rows
  | Mql_to_pgsql.Page.Affirm -> rows
  | Mql_to_pgsql.Page.Negate when excessive_rows -> CCList.drop 1 @@ CCList.rev rows
  | Mql_to_pgsql.Page.Negate -> CCList.rev rows

(* Work out which pagination links, if any, accompany the trimmed [rows].
   [excessive_rows] means the query saw the sentinel extra row, i.e. there is a
   further page in the direction of travel. *)
let decide_pagination ~excessive_rows ~page rows query =
  let module Ps = Mql_to_pgsql.Pages in
  let module P = Mql_to_pgsql.Page in
  let cursor p = Some (Yojson.Safe.to_string @@ P.to_yojson p) in
  match Mql_to_pgsql.pages rows query with
  | Ok (Some { Ps.prev; next }) -> (
      match (excessive_rows, page) with
      | true, Some { P.dir = P.Affirm; _ } | true, Some { P.dir = P.Negate; _ } ->
          `Paginate (cursor prev, cursor next)
      | true, None -> `Paginate (None, cursor next)
      | false, None -> `No_paginate
      | false, Some { P.dir = P.Affirm; _ } -> `Paginate (cursor prev, None)
      | false, Some { P.dir = P.Negate; _ } -> `Paginate (None, cursor next))
  | Ok None -> if excessive_rows then `Missing_order_by else `No_paginate
  | Error err -> (
      if not excessive_rows then `No_paginate
      else
        match err with
        | `Column_not_in_row_err col -> `Paginate_err ("COLUMN_NOT_IN_ROW " ^ col)
        | `Order_by_col_not_identifier_err e ->
            `Paginate_err ("ORDER_BY_COL_NOT_IDENTIFIER " ^ Mql.Ast.expr_to_string e))

let run_query ~admin config storage user installation_id q tz page =
  let open Abbs_future_combinators.Infix_result_monad in
  let q = CCOption.get_or ~default:"" q in
  Abb.Future.return (parse_page page)
  >>= fun page ->
  build_query q page
  >>= fun (query, limit) ->
  execute_query ~admin config storage user installation_id tz query
  >>= fun rows ->
  let excessive_rows = CCList.length rows > limit in
  let rows = trim_rows ~limit ~page ~excessive_rows rows in
  Abb.Future.return (Ok (decide_pagination ~excessive_rows ~page rows query, rows))

let respond_rows ?headers ctx rows =
  let body = Yojson.Safe.to_string (`List rows) in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ?headers ~status:`OK body) ctx)

let respond_bad_request ctx id data =
  let body = Yojson.Safe.to_string @@ Er.to_yojson { Er.id; data } in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)

let log_mql_bad ctx id pp err data =
  Logs.info (fun m -> m "%s : %a" (Brtl_ctx.token ctx) pp err);
  respond_bad_request ctx id data

let respond_internal_error ctx =
  Abb.Future.return
    (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

let pagination_error_headers err = Cohttp.Header.of_list [ ("mql-pagination-error", err) ]

let respond ctx = function
  | Ok (`Paginate pagination, rows) ->
      respond_rows ~headers:(mk_pagination_headers pagination ctx) ctx rows
  | Ok (`Paginate_err err, rows) -> respond_rows ~headers:(pagination_error_headers err) ctx rows
  | Ok (`Missing_order_by, rows) ->
      respond_rows ~headers:(pagination_error_headers "ORDER_BY_MISSING") ctx rows
  | Ok (`No_paginate, rows) -> respond_rows ctx rows
  | Error `Page_err -> respond_bad_request ctx "PAGE_ERR" None
  | Error (#Mql_to_pgsql.apply_page_err as err) ->
      log_mql_bad
        ctx
        "APPLY_PAGE_ERR"
        Mql_to_pgsql.pp_apply_page_err
        err
        (Some (Mql_to_pgsql.show_apply_page_err err))
  | Error (`Table_access_err name as err) ->
      log_mql_bad ctx "TABLE_ACCESS_ERR" Mql_to_pgsql.pp_of_mql_err err (Some name)
  | Error (`Func_access_err name as err) ->
      log_mql_bad ctx "FUNC_ACCESS_ERR" Mql_to_pgsql.pp_of_mql_err err (Some name)
  | Error (`Cast_err name as err) ->
      log_mql_bad ctx "CAST_ERR" Mql_to_pgsql.pp_of_mql_err err (Some name)
  | Error (`Type_mismatch_err _ as err) ->
      log_mql_bad
        ctx
        "TYPE_MISMATCH_ERR"
        Mql_to_pgsql.pp_of_mql_err
        err
        (Some (Mql_to_pgsql.show_of_mql_err err))
  | Error (`Unknown_column_err column as err) ->
      log_mql_bad ctx "UNKNOWN_COLUMN_ERR" Mql_to_pgsql.pp_of_mql_err err (Some column)
  | Error (`Invalid_identifier_err name as err) ->
      log_mql_bad ctx "INVALID_IDENTIFIER_ERR" Mql_to_pgsql.pp_of_mql_err err (Some name)
  | Error (`Ambiguous_column_err column as err) ->
      log_mql_bad ctx "AMBIGUOUS_COLUMN_ERR" Mql_to_pgsql.pp_of_mql_err err (Some column)
  | Error (#Mql.Ast.err as err) ->
      log_mql_bad ctx "QUERY_ERR" Mql.Ast.pp_err err (Some (Mql.Ast.show_err err))
  | Error (`Syntax_err { Pgsql_io.message; _ } as err) ->
      Logs.info (fun m -> m "%s : QUERY_SYNTAX_ERR : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
      respond_bad_request ctx "QUERY_ERR" (Some message)
  | Error (`Pgsql_err { Pgsql_io.message; _ } as err) ->
      Logs.info (fun m -> m "%s : QUERY_PGSQL_ERR : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
      respond_bad_request ctx "QUERY_ERR" (Some message)
  | Error `Statement_timeout -> respond_bad_request ctx "TIMEOUT_ERR" None
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
      respond_internal_error ctx
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
      respond_internal_error ctx

module type S = sig
  module Account_id : Terrat_vcs_api.ID

  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    Account_id.t ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module Make (S : S with type Account_id.t = int) = struct
  let enforce_installation_access storage user installation_id ctx =
    if Terrat_user.has_capability Terrat_user.Capability.Mql_admin user then
      (* The [Mql_admin] capability grants MQL access to any installation. This
         bypass is intentionally scoped to the MQL endpoint and not placed in the
         shared provider [enforce_installation_access]. *)
      Abb.Future.return (Ok ())
    else
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          S.enforce_installation_access ~request_id:(Brtl_ctx.token ctx) user installation_id db)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))

  let run config storage installation_id q tz page =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let admin = Terrat_user.has_capability Terrat_user.Capability.Mql_admin user in
        let open Abb.Future.Infix_monad in
        run_query ~admin config storage (Terrat_user.id user) installation_id q tz page
        >>= respond ctx
        >>= fun ctx -> Abb.Future.return (Ok ctx))

  module Schema = struct
    let get _config storage installation_id =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let body = Yojson.Safe.to_string @@ Mql_to_pgsql.Schema.to_yojson schema in
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)))
  end
end
