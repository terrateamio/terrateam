module Api = Terrat_vcs_api_github
module Tmpl = Terrat_vcs_github_comment_templates.Tmpl
module Ui = Terrat_vcs_github_comment_ui.Ui
module Unified = Terrat_vcs_comment_unified

let src = Logs.Src.create "vcs_github_comment_unified"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let read s = Pgsql_io.clean_string s

  let upsert_unified_comment_dirty =
    Pgsql_io.Typed_sql.(
      sql /^ read [%blob "sql/upsert_unified_comment_dirty.sql"] /% Var.uuid "work_manifest")

  let mark_unified_comment_dirty =
    Pgsql_io.Typed_sql.(
      sql /^ read [%blob "sql/mark_unified_comment_dirty.sql"] /% Var.uuid "work_manifest")

  let select_unified_comment_state =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* repository *)
      Ret.bigint
      //
      (* pull_number *)
      Ret.bigint
      //
      (* installation_id *)
      Ret.bigint
      //
      (* repo_owner *)
      Ret.text
      //
      (* repo_name *)
      Ret.text
      //
      (* comment_id *)
      Ret.(option bigint)
      //
      (* dirty *)
      Ret.bigint
      /^ read [%blob "sql/select_unified_comment_state.sql"]
      /% Var.uuid "work_manifest")

  let select_unified_comment_elements () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* path *)
      Ret.text
      //
      (* workspace *)
      Ret.text
      //
      (* plan_success *)
      Ret.(option boolean)
      //
      (* plan_has_changes *)
      Ret.(option boolean)
      //
      (* plan_work_manifest *)
      Ret.(option uuid)
      //
      (* created *)
      Ret.(option bigint)
      //
      (* updated *)
      Ret.(option bigint)
      //
      (* deleted *)
      Ret.(option bigint)
      //
      (* replaced *)
      Ret.(option bigint)
      //
      (* plan_output *)
      Ret.(option text)
      //
      (* apply_success *)
      Ret.(option boolean)
      //
      (* apply_work_manifest *)
      Ret.(option uuid)
      //
      (* active *)
      Ret.boolean
      //
      (* aborted *)
      Ret.boolean
      /^ read [%blob "sql/select_unified_comment_elements.sql"]
      /% Var.uuid "work_manifest")

  let update_unified_comment_id =
    Pgsql_io.Typed_sql.(
      sql
      /^ read [%blob "sql/update_unified_comment_id.sql"]
      /% Var.bigint "comment_id"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let clear_unified_comment_dirty =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* repository *)
      Ret.bigint
      /^ read [%blob "sql/clear_unified_comment_dirty.sql"]
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.bigint "dirty")

  let try_advisory_lock =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* locked *)
      Ret.boolean
      /^ "select pg_try_advisory_xact_lock(hashtext('github_unified_comments'), hashtext($key))"
      /% Var.text "key")
end

module S = struct
  type t = {
    account : Api.Account.t;
    client : Githubc2_abb.t;
    comment_id : Api.Comment.Id.t option;
    config : Api.Config.t;
    db : Pgsql_io.t;
    pull_number : int64;
    repo_name : string;
    repo_owner : string;
    repository : int64;
    request_id : string;
    work_manifest_id : Uuidm.t;
  }

  type el = {
    created : int64 option;
    deleted : int64 option;
    dirspace : Terrat_dirspace.t;
    has_changes : bool;
    output : string option;
    replaced : int64 option;
    status : Unified.Status.t;
    updated : int64 option;
    work_manifest_id : Uuidm.t option;
  }
  [@@deriving ord, show]

  type comment_id = Api.Comment.Id.t [@@deriving ord, show]

  let status_of_row ~plan_success ~apply_success ~active ~aborted =
    let module St = Unified.Status in
    match (apply_success, active, plan_success) with
    | Some true, _, _ -> St.Applied
    | Some false, _, _ -> St.Failed
    | None, true, _ -> St.Pending
    | None, false, Some false -> St.Failed
    | None, false, Some true -> St.Planned
    | None, false, None -> if aborted then St.Failed else St.Pending

  let query_comment_id t = Abb.Future.return (Ok t.comment_id)

  let query_els t =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      t.db
      (Sql.select_unified_comment_elements ())
      ~f:(fun
          path
          workspace
          plan_success
          plan_has_changes
          plan_work_manifest
          created
          updated
          deleted
          replaced
          plan_output
          apply_success
          apply_work_manifest
          active
          aborted
        ->
        {
          created;
          deleted;
          dirspace = { Terrat_dirspace.dir = path; workspace };
          has_changes = CCOption.get_or ~default:false plan_has_changes;
          output = plan_output;
          replaced;
          status = status_of_row ~plan_success ~apply_success ~active ~aborted;
          updated;
          work_manifest_id = CCOption.or_ ~else_:plan_work_manifest apply_work_manifest;
        })
      t.work_manifest_id
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let status_kv status =
    let module St = Unified.Status in
    match status with
    | St.Failed -> ":x: **Failed**"
    | St.Planned -> ":pencil2: Planned"
    | St.Pending -> ":hourglass_flowing_sand: Pending"
    | St.Applied -> ":white_check_mark: Applied"

  let status_machine status =
    let module St = Unified.Status in
    match status with
    | St.Failed -> "failed"
    | St.Planned -> "planned"
    | St.Pending -> "pending"
    | St.Applied -> "applied"

  let count_kv el count =
    match (el.status, el.has_changes, count) with
    | Unified.Status.Pending, _, _ | _, false, _ | _, _, None -> "-"
    | _, true, Some n -> Int64.to_string n

  let run_url t el =
    CCOption.map
      (fun work_manifest_id ->
        Uri.to_string
        @@ CCOption.get_exn_or "run_url"
        @@ Ui.run_url t.config t.account work_manifest_id)
      el.work_manifest_id

  let console_url t = Printf.sprintf "%s/runs/pr/%Ld" (Ui.base_url t.config t.account) t.pull_number

  let sum f els =
    CCList.fold_left (fun acc el -> Int64.add acc (CCOption.get_or ~default:0L (f el))) 0L els

  let machine_kv t els =
    let json =
      `Assoc
        [
          ( "dirspaces",
            `List
              (CCList.map
                 (fun el ->
                   let { Terrat_dirspace.dir; workspace } = el.dirspace in
                   `Assoc
                     [
                       ("dir", `String dir);
                       ("workspace", `String workspace);
                       ("status", `String (status_machine el.status));
                       ("has_changes", `Bool el.has_changes);
                       ( "created",
                         CCOption.map_or ~default:`Null (fun n -> `Intlit (Int64.to_string n))
                         @@ el.created );
                       ( "updated",
                         CCOption.map_or ~default:`Null (fun n -> `Intlit (Int64.to_string n))
                         @@ el.updated );
                       ( "deleted",
                         CCOption.map_or ~default:`Null (fun n -> `Intlit (Int64.to_string n))
                         @@ el.deleted );
                       ( "replaced",
                         CCOption.map_or ~default:`Null (fun n -> `Intlit (Int64.to_string n))
                         @@ el.replaced );
                       ( "run_url",
                         CCOption.map_or ~default:`Null (fun url -> `String url) @@ run_url t el );
                     ])
                 els) );
        ]
    in
    (* "--" may not appear inside an HTML comment; encode it away using JSON
       unicode escapes so the payload stays valid JSON. *)
    CCString.replace ~sub:"--" ~by:"\\u002d\\u002d" (Yojson.Safe.to_string json)

  let render t tier els =
    let module T = Unified.Tier in
    let num_els = CCList.length els in
    let shown =
      match tier with
      | T.Details _ | T.Table -> els
      | T.Truncated n -> CCList.take n els
    in
    let details =
      match tier with
      | T.Details n ->
          CCList.filter (fun el -> not (CCOption.is_none el.output)) (CCList.take n els)
      | T.Table | T.Truncated _ -> []
    in
    let count_status status =
      CCList.length (CCList.filter (fun el -> Unified.Status.compare el.status status = 0) els)
    in
    let kv =
      `Assoc
        [
          ("num_dirspaces", `Int num_els);
          ("num_failed", `Int (count_status Unified.Status.Failed));
          ("num_planned", `Int (count_status Unified.Status.Planned));
          ("num_pending", `Int (count_status Unified.Status.Pending));
          ("num_applied", `Int (count_status Unified.Status.Applied));
          ( "dirspaces",
            `List
              (CCList.map
                 (fun el ->
                   let { Terrat_dirspace.dir; workspace } = el.dirspace in
                   `Assoc
                     [
                       ("dir", `String dir);
                       ("workspace", `String workspace);
                       ("status", `String (status_kv el.status));
                       ("created", `String (count_kv el el.created));
                       ("updated", `String (count_kv el el.updated));
                       ("replaced", `String (count_kv el el.replaced));
                       ("deleted", `String (count_kv el el.deleted));
                       ( "run_url",
                         CCOption.map_or ~default:`Null (fun url -> `String url) @@ run_url t el );
                     ])
                 shown) );
          ( "totals",
            `Assoc
              [
                ("created", `String (Int64.to_string (sum (fun el -> el.created) els)));
                ("updated", `String (Int64.to_string (sum (fun el -> el.updated) els)));
                ("replaced", `String (Int64.to_string (sum (fun el -> el.replaced) els)));
                ("deleted", `String (Int64.to_string (sum (fun el -> el.deleted) els)));
              ] );
          ("truncated", `Int (num_els - CCList.length shown));
          ("console_url", `String (console_url t));
          ( "details",
            `List
              (CCList.map
                 (fun el ->
                   let { Terrat_dirspace.dir; workspace } = el.dirspace in
                   `Assoc
                     [
                       ("dir", `String dir);
                       ("workspace", `String workspace);
                       ("output", `String (CCOption.get_or ~default:"" el.output));
                     ])
                 details) );
          ( "show_apply_hint",
            `Bool
              (CCList.exists
                 (fun el ->
                   Unified.Status.compare el.status Unified.Status.Planned = 0 && el.has_changes)
                 els) );
          ( "machine",
            match tier with
            | T.Details _ | T.Table -> `String (machine_kv t els)
            | T.Truncated _ -> `Null );
        ]
    in
    match Minijinja.render_template Tmpl.unified_comment kv with
    | Ok body -> body
    | Error err ->
        Logs.err (fun m -> m "%s : ERROR : %s" t.request_id err);
        assert false

  let update_comment t comment_id body =
    let open Abb.Future.Infix_monad in
    Terrat_github.update_comment
      ~owner:t.repo_owner
      ~repo:t.repo_name
      ~comment_id:
        (Api.Comment.Id.to_string comment_id |> CCInt.of_string |> CCOption.get_exn_or "comment_id")
      ~body
      t.client
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Not_found -> Abb.Future.return (Error `Not_found)
    | Error (#Terrat_github.update_comment_err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Terrat_github.pp_update_comment_err err);
        Abb.Future.return (Error `Error)

  let post_comment t body =
    let open Abb.Future.Infix_monad in
    Terrat_github.publish_comment
      ~owner:t.repo_owner
      ~repo:t.repo_name
      ~pull_number:(CCInt64.to_int t.pull_number)
      ~body
      t.client
    >>= function
    | Ok comment_id -> (
        match Api.Comment.Id.of_string (CCInt.to_string comment_id) with
        | Some comment_id -> Abb.Future.return (Ok comment_id)
        | None -> Abb.Future.return (Error `Error))
    | Error (#Terrat_github.publish_comment_err as err) ->
        Logs.err (fun m ->
            m "%s : ERROR : %a" t.request_id Terrat_github.pp_publish_comment_err err);
        Abb.Future.return (Error `Error)

  let upsert_comment_id t comment_id =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.execute
      t.db
      Sql.update_unified_comment_id
      (Int64.of_int
         (Api.Comment.Id.to_string comment_id |> CCInt.of_string |> CCOption.get_exn_or "comment_id"))
      t.repository
      t.pull_number
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let dirspace el = el.dirspace
  let status el = el.status
  let has_changes el = el.has_changes

  (* GitHub limits comments to 65536 characters.  Leave some margin for
     good measure. *)
  let max_comment_length = 65536 - 512
end

module Publisher = Unified.Make (S)

let mark_dirty ~request_id db work_manifest_id =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.execute db Sql.upsert_unified_comment_dirty work_manifest_id
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%s : ERROR : %a" request_id Pgsql_io.pp_err err);
      Abb.Future.return (Error `Error)

let mark_dirty_if_tracked ~request_id db work_manifest_id =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.execute db Sql.mark_unified_comment_dirty work_manifest_id
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%s : ERROR : %a" request_id Pgsql_io.pp_err err);
      Abb.Future.return (Error `Error)

(* One refresh attempt.  Runs in its own transaction on its own connection so
   the advisory lock and the GitHub API calls never extend a result
   transaction.  Returns [`Race] when new results marked the comment dirty
   while we were publishing, in which case the caller retries. *)
let refresh ~request_id config storage work_manifest_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_unified_comment_state
            ~f:(fun repository pull_number installation_id repo_owner repo_name comment_id dirty ->
              (repository, pull_number, installation_id, repo_owner, repo_name, comment_id, dirty))
            work_manifest_id
          >>= function
          | [] | (_, _, _, _, _, _, 0L) :: _ -> Abb.Future.return (Ok `Done)
          | (repository, pull_number, installation_id, repo_owner, repo_name, comment_id, dirty)
            :: _ -> (
              let key = Printf.sprintf "%Ld:%Ld" repository pull_number in
              Pgsql_io.Prepared_stmt.fetch db Sql.try_advisory_lock ~f:CCFun.id key
              >>= function
              | [ false ] ->
                  (* Another drain is publishing; it will pick up our dirty
                     mark or the next result will. *)
                  Abb.Future.return (Ok `Done)
              | _ -> (
                  let account = Api.Account.make (CCInt64.to_int installation_id) in
                  Api.create_client ~request_id config account db
                  >>= fun client ->
                  let t =
                    {
                      S.account;
                      client = Api.Client.to_native client;
                      comment_id =
                        CCOption.flat_map
                          CCFun.(Int64.to_string %> Api.Comment.Id.of_string)
                          comment_id;
                      config;
                      db;
                      pull_number;
                      repo_name;
                      repo_owner;
                      repository;
                      request_id;
                      work_manifest_id;
                    }
                  in
                  Publisher.run t
                  >>= fun () ->
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    Sql.clear_unified_comment_dirty
                    ~f:CCFun.id
                    repository
                    pull_number
                    dirty
                  >>= function
                  | [] -> Abb.Future.return (Ok `Race)
                  | _ :: _ -> Abb.Future.return (Ok `Done)))))

let drain ~request_id config storage work_manifest_id =
  let open Abb.Future.Infix_monad in
  let rec attempt n =
    if n <= 0 then (
      (* The dirty counter is still set; the next drain of this pull request
         picks it up. *)
      Logs.warn (fun m ->
          m
            "%s : DRAIN_UNIFIED_COMMENT : RETRIES_EXHAUSTED : %a"
            request_id
            Uuidm.pp
            work_manifest_id);
      Abb.Future.return (Ok `Done))
    else
      refresh ~request_id config storage work_manifest_id
      >>= function
      | Ok `Done -> Abb.Future.return (Ok `Done)
      | Ok `Race -> attempt (n - 1)
      | Error _ as err -> Abb.Future.return err
  in
  attempt 3
  >>= function
  | Ok `Done -> Abb.Future.return ()
  | Error `Error ->
      Logs.err (fun m -> m "%s : DRAIN_UNIFIED_COMMENT : ERROR" request_id);
      Abb.Future.return ()
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "%s : DRAIN_UNIFIED_COMMENT : %a" request_id Pgsql_pool.pp_err err);
      Abb.Future.return ()
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%s : DRAIN_UNIFIED_COMMENT : %a" request_id Pgsql_io.pp_err err);
      Abb.Future.return ()
