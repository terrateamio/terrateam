module Work_manifests = struct
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

    let replace_where q where = CCString.replace ~sub:"{{where}}" ~by:where q

    let dirspaces =
      let module T = struct
        type t = Terrat_api_components.Work_manifest_dirspace.t list [@@deriving yojson]
      end in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map T.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let set_timeout timeout =
      Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

    let select_work_manifests where =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.uuid
        // (* base_hash *) Ret.text
        // (* completed_at *) Ret.(option text)
        // (* created_at *) Ret.text
        // (* hash *) Ret.text
        // (* run_type *) Ret.ud' Terrat_work_manifest3.Step.of_string
        // (* state *) Ret.ud' Terrat_work_manifest3.State.of_string
        // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        // (* repository *) Ret.bigint
        // (* pull_number *) Ret.(option bigint)
        // (* base_branch *) Ret.text
        // (* owner *) Ret.text
        // (* repo *) Ret.text
        // (* run_kind *) Ret.text
        // (* dirspaces *) Ret.(option (ud' dirspaces))
        // (* pull_request_title *) Ret.(option text)
        // (* branch *) Ret.(option text)
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

  module Tag_query_sql = struct
    type t = {
      q : Buffer.t;
      strings : string CCVector.vector;
      bigints : int64 CCVector.vector;
      json : string CCVector.vector;
      timezone : string;
      mutable sort_dir : [ `Asc | `Desc ];
      mutable sort_by : string;
    }

    let empty ?(timezone = "UTC") () =
      {
        q = Buffer.create 50;
        strings = CCVector.create ();
        bigints = CCVector.create ();
        json = CCVector.create ();
        timezone;
        sort_dir = `Desc;
        sort_by = "created_at";
      }

    let append_uuid_equal t n v =
      CCVector.push t.strings v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]::uuid" n (CCVector.size t.strings))

    let append_str_equal t n v =
      CCVector.push t.strings v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]" n (CCVector.size t.strings))

    let append_str_equal_or_null t n = function
      | "" -> Buffer.add_string t.q (Printf.sprintf "%s is null" n)
      | v ->
          CCVector.push t.strings v;
          Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]" n (CCVector.size t.strings))

    let append_bigint_equal t n v =
      CCVector.push t.bigints v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($bigints)[%d]" n (CCVector.size t.bigints))

    let date_only s = not (CCString.contains s ' ')

    let rec of_ast t =
      let module T = Terrat_tag_query_parser_value in
      function
      | T.Tag tag -> (
          match CCString.Split.left ~by:":" tag with
          | Some ("sort", "asc") ->
              t.sort_dir <- `Asc;
              (* Cheap hack but we replace these meta attributes with [true]. *)
              Buffer.add_string t.q "true";
              Ok ()
          | Some ("sort", "desc") ->
              t.sort_dir <- `Desc;
              (* Cheap hack but we replace these meta attributes with [true]. *)
              Buffer.add_string t.q "true";
              Ok ()
          | Some ("id", value) ->
              append_uuid_equal t "id" value;
              Ok ()
          | Some ("pr", value) -> (
              match CCInt64.of_string value with
              | Some value ->
                  append_bigint_equal t "pull_number" value;
                  Ok ()
              | None -> Error (`Error tag))
          | Some ("user", value) ->
              append_str_equal t "username" value;
              Ok ()
          | Some ("dir", value) ->
              CCVector.push
                t.json
                (Yojson.Safe.to_string (`List [ `Assoc [ ("dir", `String value) ] ]));
              Buffer.add_string
                t.q
                (Printf.sprintf "(dirspaces @> (($json)[%d]::jsonb))" (CCVector.size t.json));
              Ok ()
          | Some ("repo", value) ->
              append_str_equal t "name" value;
              Ok ()
          | Some ("type", value) ->
              append_str_equal t "run_type" value;
              Ok ()
          | Some ("kind", value) ->
              append_str_equal t "kind" value;
              Ok ()
          | Some ("state", value) ->
              append_str_equal t "state" value;
              Ok ()
          | Some ("branch", value) ->
              append_str_equal t "branch" value;
              Ok ()
          | Some ("environment", value) ->
              append_str_equal_or_null t "environment" value;
              Ok ()
          | Some ("workspace", value) ->
              CCVector.push
                t.json
                (Yojson.Safe.to_string (`List [ `Assoc [ ("workspace", `String value) ] ]));
              Buffer.add_string
                t.q
                (Printf.sprintf "(dirspaces @> (($json)[%d]::jsonb))" (CCVector.size t.json));
              Ok ()
          | Some ("created_at", value) -> (
              match CCString.Split.left ~by:".." value with
              | Some ("", "") -> Error (`Bad_date_format value)
              | Some (v, "") ->
                  CCVector.push t.strings v;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < now())"
                       (CCVector.size t.strings));
                  Ok ()
              | Some ("", v) ->
                  CCVector.push t.strings v;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "created_at < (to_timestamp(($strings)[%d], 'YYYY-MM-DD \
                        HH24:MI')::timestamp at time zone $tz)"
                       (CCVector.size t.strings));
                  Ok ()
              | Some (l, r) ->
                  CCVector.push t.strings l;
                  CCVector.push t.strings r;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < (to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz))"
                       (CCVector.size t.strings - 1)
                       (CCVector.size t.strings));
                  Ok ()
              | None when date_only value ->
                  CCVector.push t.strings value;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD H24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < ((to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) + interval '1 day'))"
                       (CCVector.size t.strings)
                       (CCVector.size t.strings));
                  Ok ()
              | None ->
                  CCVector.push t.strings value;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < (to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) + interval '1 min')"
                       (CCVector.size t.strings)
                       (CCVector.size t.strings));
                  Ok ())
          | Some _ | None -> Error (`Unknown_tag tag))
      | T.Or (l, r) ->
          let open CCResult.Infix in
          Buffer.add_char t.q '(';
          of_ast t l
          >>= fun () ->
          Buffer.add_string t.q ") or (";
          of_ast t r
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.And (l, r) ->
          let open CCResult.Infix in
          Buffer.add_char t.q '(';
          of_ast t l
          >>= fun () ->
          Buffer.add_string t.q ") and (";
          of_ast t r
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.Not e ->
          let open CCResult.Infix in
          Buffer.add_string t.q "not (";
          of_ast t e
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.In_dir _ -> Error `In_dir_not_supported
  end

  let columns =
    Pgsql_pagination.Search.Col.
      [ create ~vname:"prev_created_at" ~cname:"created_at"; create ~vname:"prev_id" ~cname:"id" ]

  module Page = struct
    type cursor = string * Uuidm.t

    type query = {
      user : Uuidm.t;
      query : Tag_query_sql.t option;
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
      let where, q =
        match query.query with
        | Some q -> ("where " ^ Buffer.contents q.Tag_query_sql.q, q)
        | None -> ("", Tag_query_sql.empty ())
      in
      let search =
        Pgsql_pagination.Search.(
          create ~page_size:query.limit ~dir:q.Tag_query_sql.sort_dir columns)
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
                (Sql.set_timeout (Terrat_config.statement_timeout query.config))
              >>= fun () ->
              f
                search
                db
                (Sql.select_work_manifests where)
                ~f:(fun
                    id
                    base_ref
                    completed_at
                    created_at
                    ref_
                    run_type
                    state
                    tag_query
                    repository
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
                  let module D = Terrat_api_components.Installation_work_manifest_drift in
                  let module Pr = Terrat_api_components.Installation_work_manifest_pull_request in
                  let module Idx = Terrat_api_components.Installation_work_manifest_index in
                  let module Wm = Terrat_api_components.Installation_work_manifest in
                  match (run_kind, pull_number, branch) with
                  | "drift", _, _ ->
                      Wm.Installation_work_manifest_drift
                        {
                          D.base_branch;
                          base_ref;
                          completed_at;
                          created_at;
                          dirspaces = CCOption.get_or ~default:[] dirspaces;
                          id = Uuidm.to_string id;
                          owner;
                          ref_;
                          repo;
                          repository = CCInt64.to_int repository;
                          run_type = Terrat_work_manifest3.Step.to_string run_type;
                          state = Terrat_work_manifest3.State.to_string state;
                          run_id;
                          environment;
                        }
                  | "pr", Some pull_number, Some branch ->
                      Wm.Installation_work_manifest_pull_request
                        {
                          Pr.base_branch;
                          base_ref;
                          branch;
                          completed_at;
                          created_at;
                          dirspaces = CCOption.get_or ~default:[] dirspaces;
                          id = Uuidm.to_string id;
                          owner;
                          pull_number = CCInt64.to_int pull_number;
                          pull_request_title;
                          ref_;
                          repo;
                          repository = CCInt64.to_int repository;
                          run_type = Terrat_work_manifest3.Step.to_string run_type;
                          state = Terrat_work_manifest3.State.to_string state;
                          tag_query = Terrat_tag_query.to_string tag_query;
                          user;
                          run_id;
                          environment;
                        }
                  | "index", Some pull_number, Some branch ->
                      Wm.Installation_work_manifest_index
                        {
                          Idx.base_branch;
                          base_ref;
                          branch;
                          completed_at;
                          created_at;
                          dirspaces = CCOption.get_or ~default:[] dirspaces;
                          id = Uuidm.to_string id;
                          owner;
                          pull_number = CCInt64.to_int pull_number;
                          pull_request_title;
                          ref_;
                          repo;
                          repository = CCInt64.to_int repository;
                          state = Terrat_work_manifest3.State.to_string state;
                          user;
                          run_id;
                        }
                  | _, _, _ ->
                      Logs.info (fun m -> m "Unknown run_kind %a" Uuidm.pp id);
                      raise (Failure ("Failed " ^ Uuidm.to_string id)))
                query.user
                (CCInt64.of_int query.installation_id)
                q.Tag_query_sql.timezone
                (CCVector.to_list q.Tag_query_sql.strings)
                (CCVector.to_list q.Tag_query_sql.bigints)
                (CCVector.to_list q.Tag_query_sql.json)
                created_at
                id))

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_work_manifests.Responses.OK.(
        { work_manifests = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Wm = Terrat_api_components.Installation_work_manifest in
      let module D = Terrat_api_components.Installation_work_manifest_drift in
      let module Idx = Terrat_api_components.Installation_work_manifest_index in
      let module Pr = Terrat_api_components.Installation_work_manifest_pull_request in
      function
      | Wm.Installation_work_manifest_drift D.{ id; created_at; _ }
      | Wm.Installation_work_manifest_pull_request Pr.{ id; created_at; _ }
      | Wm.Installation_work_manifest_index Idx.{ id; created_at; _ } -> Some [ created_at; id ]

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
            let query = Tag_query_sql.empty ?timezone () in
            match Tag_query_sql.of_ast query ast with
            | Ok () ->
                let query =
                  Page.
                    {
                      user = Terrat_user.id user;
                      query = Some query;
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
                    { id = "UNKNOWN_TAG"; data = Some tag } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
        | Some (Ok None) | None ->
            let query =
              Page.
                {
                  user = Terrat_user.id user;
                  query = None;
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

    let replace_where q where = CCString.replace ~sub:"{{where}}" ~by:where q

    let set_timeout timeout =
      Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

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

  module Tag_query_sql = struct
    type t = {
      q : Buffer.t;
      strings : string CCVector.vector;
      bigints : int64 CCVector.vector;
      json : string CCVector.vector;
      timezone : string;
      mutable sort_dir : [ `Asc | `Desc ];
      mutable sort_by : string;
    }

    let empty ?(timezone = "UTC") () =
      {
        q = Buffer.create 50;
        strings = CCVector.create ();
        bigints = CCVector.create ();
        json = CCVector.create ();
        timezone;
        sort_dir = `Desc;
        sort_by = "created_at";
      }

    let append_uuid_equal t n v =
      CCVector.push t.strings v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]::uuid" n (CCVector.size t.strings))

    let append_str_equal t n v =
      CCVector.push t.strings v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]" n (CCVector.size t.strings))

    let append_str_equal_or_null t n = function
      | "" -> Buffer.add_string t.q (Printf.sprintf "%s is null" n)
      | v ->
          CCVector.push t.strings v;
          Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]" n (CCVector.size t.strings))

    let append_bigint_equal t n v =
      CCVector.push t.bigints v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($bigints)[%d]" n (CCVector.size t.bigints))

    let date_only s = not (CCString.contains s ' ')

    let rec of_ast t =
      let module T = Terrat_tag_query_parser_value in
      function
      | T.Tag tag -> (
          match CCString.Split.left ~by:":" tag with
          | Some ("sort", "asc") ->
              t.sort_dir <- `Asc;
              (* Cheap hack but we replace these meta attributes with [true]. *)
              Buffer.add_string t.q "true";
              Ok ()
          | Some ("sort", "desc") ->
              t.sort_dir <- `Desc;
              (* Cheap hack but we replace these meta attributes with [true]. *)
              Buffer.add_string t.q "true";
              Ok ()
          | Some ("id", value) ->
              append_uuid_equal t "id" value;
              Ok ()
          | Some ("pr", value) -> (
              match CCInt64.of_string value with
              | Some value ->
                  append_bigint_equal t "pull_number" value;
                  Ok ()
              | None -> Error (`Error tag))
          | Some ("user", value) ->
              append_str_equal t "username" value;
              Ok ()
          | Some ("dir", value) ->
              append_str_equal t "dir" value;
              Ok ()
          | Some ("repo", value) ->
              append_str_equal t "name" value;
              Ok ()
          | Some ("type", value) ->
              append_str_equal t "run_type" value;
              Ok ()
          | Some ("kind", value) ->
              append_str_equal t "kind" value;
              Ok ()
          | Some ("state", value) ->
              append_str_equal t "state" value;
              Ok ()
          | Some ("branch", value) ->
              append_str_equal t "branch" value;
              Ok ()
          | Some ("environment", value) ->
              append_str_equal_or_null t "environment" value;
              Ok ()
          | Some ("workspace", value) ->
              append_str_equal t "workspace" value;
              Ok ()
          | Some ("created_at", value) -> (
              match CCString.Split.left ~by:".." value with
              | Some ("", "") -> Error (`Bad_date_format value)
              | Some (v, "") ->
                  CCVector.push t.strings v;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < now())"
                       (CCVector.size t.strings));
                  Ok ()
              | Some ("", v) ->
                  CCVector.push t.strings v;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "created_at < (to_timestamp(($strings)[%d], 'YYYY-MM-DD \
                        HH24:MI')::timestamp at time zone $tz)"
                       (CCVector.size t.strings));
                  Ok ()
              | Some (l, r) ->
                  CCVector.push t.strings l;
                  CCVector.push t.strings r;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < (to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz))"
                       (CCVector.size t.strings - 1)
                       (CCVector.size t.strings));
                  Ok ()
              | None when date_only value ->
                  CCVector.push t.strings value;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD H24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < ((to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) + interval '1 day'))"
                       (CCVector.size t.strings)
                       (CCVector.size t.strings));
                  Ok ()
              | None ->
                  CCVector.push t.strings value;
                  Buffer.add_string
                    t.q
                    (Printf.sprintf
                       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time \
                        zone $tz) <= created_at and created_at < (to_timestamp(($strings)[%d], \
                        'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) + interval '1 min')"
                       (CCVector.size t.strings)
                       (CCVector.size t.strings));
                  Ok ())
          | Some _ | None -> Error (`Unknown_tag tag))
      | T.Or (l, r) ->
          let open CCResult.Infix in
          Buffer.add_char t.q '(';
          of_ast t l
          >>= fun () ->
          Buffer.add_string t.q ") or (";
          of_ast t r
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.And (l, r) ->
          let open CCResult.Infix in
          Buffer.add_char t.q '(';
          of_ast t l
          >>= fun () ->
          Buffer.add_string t.q ") and (";
          of_ast t r
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.Not e ->
          let open CCResult.Infix in
          Buffer.add_string t.q "not (";
          of_ast t e
          >>= fun () ->
          Buffer.add_char t.q ')';
          Ok ()
      | T.In_dir _ -> Error `In_dir_not_supported
  end

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
      query : Tag_query_sql.t option;
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
      let where, q =
        match query.query with
        | Some q -> ("where " ^ Buffer.contents q.Tag_query_sql.q, q)
        | None -> ("", Tag_query_sql.empty ())
      in
      let search =
        Pgsql_pagination.Search.(
          create ~page_size:query.limit ~dir:q.Tag_query_sql.sort_dir columns)
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
                (Sql.set_timeout (Terrat_config.statement_timeout query.config))
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
                q.Tag_query_sql.timezone
                (CCVector.to_list q.Tag_query_sql.strings)
                (CCVector.to_list q.Tag_query_sql.bigints)
                (CCVector.to_list q.Tag_query_sql.json)
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
            let query = Tag_query_sql.empty ?timezone () in
            match Tag_query_sql.of_ast query ast with
            | Ok () ->
                let query =
                  Page.
                    {
                      user = Terrat_user.id user;
                      query = Some query;
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
                    { id = "UNKNOWN_TAG"; data = Some tag } |> to_yojson |> Yojson.Safe.to_string)
                in
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request body) ctx)))
        | Some (Ok None) | None ->
            let query =
              Page.
                {
                  user = Terrat_user.id user;
                  query = None;
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
      let search = Pgsql_pagination.Search.(create ~page_size:query.limit ~dir:`Desc columns) in
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
      let search = Pgsql_pagination.Search.(create ~page_size:query.limit ~dir:query.dir columns) in
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
