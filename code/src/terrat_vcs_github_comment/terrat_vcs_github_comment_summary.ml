module Api = Terrat_vcs_api_github
module Publisher_tools = Terrat_vcs_github_comment_publishers.Publisher_tools

let src = Logs.Src.create "vcs_github_comment_summary"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

  let select_github_summary_comment =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* comment_id *)
      Ret.bigint
      /^ read "select_github_summary_comment_id.sql"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository")

  let select_github_summary_elements =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* dir *)
      Ret.text
      //
      (* workspace *)
      Ret.text
      //
      (* state *)
      Ret.ud' Terrat_work_manifest3.State.of_string
      //
      (* unified_run_type *)
      Ret.ud' Terrat_work_manifest3.Step.of_string
      //
      (* success *)
      Ret.boolean
      //
      (* created *)
      Ret.integer
      //
      (* updated *)
      Ret.integer
      //
      (* deleted *)
      Ret.integer
      //
      (* replaced *)
      Ret.integer
      /^ read "select_github_summary_comment_elements.sql"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository")

  let upsert_github_summary_comment =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "upsert_github_summary_comment.sql"
      /% Var.bigint "comment_id"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository")
end

module S = struct
  type t = {
    client : Api.Client.t;
    config : Api.Config.t;
    db : Pgsql_io.t;
    pull_request : (unit, unit) Api.Pull_request.t;
    request_id : string;
    repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t;
    synthesized_config : Terrat_change_match3.Config.t;
  }

  type el = {
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    status : string;
    stats : Terrat_vcs_comment_summary.tf_stats;
  }
  [@@deriving show]

  type comment_id = Api.Comment.Id.t [@@deriving ord, show]

  module Cmp = struct
    type t = bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t ~pull_number ~repo =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      t.db
      Sql.select_github_summary_comment
      ~f:CCFun.(Int64.to_string %> Api.Comment.Id.of_string)
      pull_number
      repo
    >>= function
    | Ok r -> Abb.Future.return (Ok (CCOption.of_list r |> CCOption.flat_map CCFun.id))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_summary_elements t ~pull_number ~repo =
    let open Abb.Future.Infix_monad in
    let module Vcs_sm = Terrat_vcs_comment_summary in
    let module Wm_state = Terrat_work_manifest3.State in
    let module Wm_step = Terrat_work_manifest3.Step in
    let format_query_result
        (dir, workspace, state, unified_run_type, is_success, created, updated, deleted, replaced) =
      let dirspace = { Terrat_dirspace.dir; workspace } in
      let status =
        match (unified_run_type, state, is_success) with
        | Wm_step.Apply, _, true -> "APPLIED"
        | Wm_step.Apply, _, false -> "FAILED"
        | Wm_step.Plan, Wm_state.Completed, true -> "PLANNED"
        | Wm_step.Plan, Wm_state.Completed, false -> "FAILED"
        | _, Wm_state.Queued, _ -> "PENDING"
        | _, Wm_state.Running, _ -> "PENDING"
        | _, Wm_state.Aborted, _ -> "FAILED"
        | _ -> "-"
      in
      let stats =
        {
          Vcs_sm.created = Int32.to_int created;
          updated = Int32.to_int updated;
          deleted = Int32.to_int deleted;
          replaced = Int32.to_int replaced;
        }
      in
      { dirspace; is_success; status; stats }
    in
    Pgsql_io.Prepared_stmt.fetch
      t.db
      Sql.select_github_summary_elements
      ~f:(fun dir w state urt is c u d r -> (dir, w, state, urt, is, c, u, d, r))
      pull_number
      repo
    >>= function
    | Ok tuples ->
        let els = CCList.map format_query_result tuples in
        Abb.Future.return (Ok els)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let upsert_summary t comment_id ~pull_number ~repo =
    let open Abb.Future.Infix_monad in
    let cid = Api.Comment.Id.to_string comment_id |> Int64.of_string in
    Pgsql_io.Prepared_stmt.execute t.db Sql.upsert_github_summary_comment cid pull_number repo
    >>= function
    | Ok _ -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let minimize_comment t comment_id =
    let request_id = t.request_id in
    Api.minimize_pull_request_comment ~request_id t.client t.pull_request comment_id

  let post_comment t els =
    let open Abbs_future_combinators.Infix_result_monad in
    let module D = Terrat_dirspace in
    let module Csm = Terrat_vcs_comment_summary in
    let module Pts = Terrat_vcs_github_comment_publishers.Publisher_tools in
    let elements =
      CCList.map
        (fun e ->
          let { D.dir; workspace } = e.dirspace in
          let status = e.status in
          let created, replaced, updated, deleted =
            (e.stats.Csm.created, e.stats.Csm.replaced, e.stats.Csm.updated, e.stats.Csm.deleted)
          in
          { Pts.dir; workspace; status; created; replaced; updated; deleted })
        els
    in
    let body = Pts.create_summary_output t.request_id elements in
    let content_length = CCString.length body in
    Logs.info (fun m -> m "%s : RENDERED_LENGTH %i" t.request_id content_length);
    let request_id = t.request_id in
    Api.comment_on_pull_request ~request_id t.client t.pull_request body
    >>= fun comment_id -> Abb.Future.return (Ok comment_id)

  let rendered_length t els =
    let module D = Terrat_dirspace in
    let module Csm = Terrat_vcs_comment_summary in
    let module Pts = Terrat_vcs_github_comment_publishers.Publisher_tools in
    let elements =
      CCList.map
        (fun e ->
          let { D.dir; workspace } = e.dirspace in
          let status = e.status in
          let created, replaced, updated, deleted =
            (e.stats.Csm.created, e.stats.Csm.replaced, e.stats.Csm.updated, e.stats.Csm.deleted)
          in
          { Pts.dir; workspace; status; created; replaced; updated; deleted })
        els
    in
    let body = Pts.create_summary_output t.request_id elements in
    CCString.length body

  let pull_request t = Int64.of_int (Api.Pull_request.id t.pull_request)

  let repo t =
    let r = Terrat_pull_request.repo t.pull_request in
    Int64.of_int (Api.Repo.id r)

  let repo_config t = t.repo_config
  let compare_el el1 el2 = Cmp.compare (el1.is_success, el1.dirspace) (el2.is_success, el2.dirspace)
  let max_comment_length = 65536 / 2
end
