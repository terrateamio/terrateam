module Api = Terrat_vcs_api_github
module By_scope = Terrat_scope.By_scope
module Publisher_tools = Terrat_vcs_github_comment_publishers.Publisher_tools
module Output = Terrat_vcs_github_comment_publishers.Output
module Scope = Terrat_scope.Scope
module Tmpl = Terrat_vcs_github_comment_templates.Tmpl
module Ui = Terrat_vcs_github_comment_ui.Ui
module Visible_on = Terrat_base_repo_config_v1.Workflow_step.Visible_on

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

  let select_comment_id =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* comment_id *)
      Ret.bigint
      /^ read "select_comment_id.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "dir"
      /% Var.text "workspace")

  let select_comment_elements =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* work_manifest_id *)
      Ret.uuid
      //
      (* comment.dir *)
      Ret.text
      //
      (* comment.workspace *)
      Ret.text
      //
      (* work_manifest.run_type *)
      Ret.text
      //
      (* steps.ignore_errors *)
      Ret.boolean
      //
      (* steps.payload *)
      Ret.ud'
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.flat_map
               (Terrat_api_components_workflow_step_output.Payload.of_yojson %> CCOption.of_result))
      //
      (* steps.scope *)
      Ret.ud'
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.flat_map
               (Terrat_api_components_workflow_step_output_scope.of_yojson %> CCOption.of_result))
      //
      (* steps.success *)
      Ret.boolean
      //
      (* steps.step *)
      Ret.text
      /^ read "select_comment_elements.sql"
      /% Var.bigint "comment_id")

  let upsert_github_work_manifest_comment =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* comment_id *)
      Ret.bigint
      /^ read "upsert_github_work_manifest_comment.sql"
      /% Var.bigint "comment_id"
      /% Var.uuid "work_manifest"
      /% Var.text "dir"
      /% Var.text "workspace")
end

module S = struct
  type t = {
    account_status : Terrat_vcs_provider2.Account_status.t;
    client : Api.Client.t;
    config : Api.Config.t;
    db : Pgsql_io.t;
    (* gates : Terrat_gate.t list; *)
    is_layered_run : bool;
    hooks : (Scope.t * Terrat_api_components_workflow_step_output.t list) list;
    pull_request : (unit, unit) Api.Pull_request.t;
    request_id : string;
    remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
    result : Terrat_api_components_work_manifest_tf_operation_result2.t;
    repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t;
    synthesized_config : Terrat_change_match3.Config.t;
    (* Curr Work M that is finished! *)
    work_manifest : (Api.Account.t, unit) Terrat_work_manifest3.Existing.t;
  }

  type el = {
    compact : bool;
    dirspace : Terrat_dirspace.t;
    steps : Terrat_api_components_workflow_step_output.t list;
    strategy : Terrat_vcs_comment.Strategy.t;
        (* WM that is already part of el *)
        (* work_manifest : (Api.Account.t, unit) Terrat_work_manifest3.Existing.t; *)
  }
  [@@deriving show]

  type comment_id = Api.Comment.Id.t [@@deriving ord, show]

  module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end

  (* TODO: Refactor this later *)
  let create_el t dirspace steps =
    let module St = Terrat_vcs_comment.Strategy in
    let module Cm3 = Terrat_change_match3 in
    let module Brc1 = Terrat_base_repo_config_v1 in
    let module N = Terrat_base_repo_config_v1.Notifications in
    let from_base_repo_policy_strategy st =
      match st with
      | N.Policy.Strategy.Append -> St.Append
      | N.Policy.Strategy.Minimize -> St.Minimize
      | N.Policy.Strategy.Delete -> St.Delete
    in
    let notification = Terrat_base_repo_config_v1.notifications t.repo_config in
    let policies = notification.N.policies in
    match Cm3.of_dirspace t.synthesized_config dirspace with
    | Some config ->
        let strategy =
          match
            CCList.find_opt
              (fun p -> Cm3.match_tag_query ~tag_query:p.N.Policy.tag_query config)
              policies
          with
          | Some { N.Policy.comment_strategy; _ } -> from_base_repo_policy_strategy comment_strategy
          | None -> Terrat_vcs_comment.Strategy.Minimize
        in
        (* I think it makes no sense dealing with this here, `terrat_vcs_comment`
           already knows how to handle that, so hardcoding may be fine *)
        let compact = false in
        Some { dirspace; steps; strategy; compact }
    | _ -> None

  let query_comment_id t el =
    let open Abb.Future.Infix_monad in
    let work_manifest_id = t.work_manifest.Terrat_work_manifest3.id in
    let { Terrat_dirspace.dir; workspace } = el.dirspace in
    Pgsql_io.Prepared_stmt.fetch
      t.db
      Sql.select_comment_id
      ~f:CCFun.id
      work_manifest_id
      dir
      workspace
    >>= function
    | Ok r ->
        Abb.Future.return
          (Ok
             (CCOption.of_list r
             |> CCOption.flat_map CCFun.(Int64.to_string %> Api.Comment.Id.of_string)))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_els_for_comment_id t comment_id =
    let open Abb.Future.Infix_monad in
    let module D = Terrat_api_components_workflow_step_output_scope_dirspace in
    let module Step = Terrat_api_components_workflow_step_output in
    let module Scope = Terrat_api_components_workflow_step_output_scope in
    let cid = Api.Comment.Id.to_string comment_id |> Int64.of_string in

    let module By_scope = Terrat_data.Group_by (struct
      type t = Uuidm.t * string * Step.t
      type key = Uuidm.t * string * Terrat_dirspace.t [@@deriving ord]

      let key (work_manifest_id, run_type, step) =
        match step.Step.scope with
        | Scope.Workflow_step_output_scope_dirspace { D.dir; workspace; _ } ->
            let dirspace = { Terrat_dirspace.dir; workspace } in
            (work_manifest_id, run_type, dirspace)
        | _ -> assert false

      let compare = compare_key
    end) in
    Pgsql_io.Prepared_stmt.fetch
      t.db
      Sql.select_comment_elements
      ~f:(fun wmid _ _ run_type ignore_errors payload scope success step ->
        (wmid, run_type, { Step.ignore_errors; payload; scope; step; success }))
      cid
    >>= function
    | Ok elements ->
        let groups = By_scope.group elements in
        let split =
          CCList.map
            (fun ((wid, run_type, d), v) -> (wid, run_type, d, CCList.map (fun (_, _, s) -> s) v))
            groups
        in
        let els =
          CCList.filter_map (fun (_, _, dirspace, steps) -> create_el t dirspace steps) split
        in
        Abb.Future.return (Ok els)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let upsert_comment_id t els comment_id =
    let open Abb.Future.Infix_monad in
    let cid = Api.Comment.Id.to_string comment_id |> Int64.of_string in
    let work_manifest_id = t.work_manifest.Terrat_work_manifest3.id in
    Abbs_future_combinators.List_result.map
      ~f:(fun el ->
        let { Terrat_dirspace.dir; workspace } = el.dirspace in
        Pgsql_io.Prepared_stmt.fetch
          t.db
          Sql.upsert_github_work_manifest_comment
          ~f:(fun _ -> ())
          cid
          work_manifest_id
          dir
          workspace)
      els
    >>= function
    | Ok _ -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "%s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let delete_comment t comment_id =
    let request_id = t.request_id in
    Api.delete_pull_request_comment ~request_id t.client t.pull_request comment_id

  let minimize_comment t comment_id =
    let request_id = t.request_id in
    Api.minimize_pull_request_comment ~request_id t.client t.pull_request comment_id

  let post_comment t els =
    let open Abbs_future_combinators.Infix_result_monad in
    let module R2 = Terrat_api_components.Work_manifest_tf_operation_result2 in
    (* TODO: Stop using the result, move gates to to t *)
    let gates = t.result.R2.gates in
    let by_dirspace = CCList.map (fun el -> (Scope.Dirspace el.dirspace, el.steps)) els in
    let by_scope = t.hooks @ by_dirspace in
    let compact = CCList.exists (fun { compact; _ } -> compact) els in
    let body =
      Publisher_tools.create_run_output
        ~view:(if compact then `Compact else `Full)
        t.request_id
        t.account_status
        t.config
        t.is_layered_run
        t.remaining_layers
        by_scope
        gates
        t.work_manifest
    in
    let request_id = t.request_id in
    Api.comment_on_pull_request ~request_id t.client t.pull_request body
    >>= fun comment_id ->
    let cid = Api.Comment.Id.to_string comment_id in
    Logs.debug (fun m -> m "%s : PUBLISHED_GITHUB_COMMENT : %s" request_id cid);
    Abb.Future.return (Ok comment_id)

  let rendered_length t els =
    let module R2 = Terrat_api_components.Work_manifest_tf_operation_result2 in
    let gates = t.result.R2.gates in
    let by_dirspace = CCList.map (fun el -> (Scope.Dirspace el.dirspace, el.steps)) els in
    let by_scope = t.hooks @ by_dirspace in
    let compact = CCList.exists (fun { compact; _ } -> compact) els in
    let out =
      Publisher_tools.create_run_output
        ~view:(if compact then `Compact else `Full)
        t.request_id
        t.account_status
        t.config
        t.is_layered_run
        t.remaining_layers
        by_scope
        gates
        t.work_manifest
    in
    CCString.length out

  let strategy el = el.strategy
  let compact el = { el with compact = true }

  let compare_el el1 el2 =
    let module P = Terrat_vcs_github_comment_publishers in
    P.dirspace_compare (el1.dirspace, el1.steps) (el2.dirspace, el2.steps)

  (* Github Limits it to 2^16 = 65536
     https://github.com/mshick/add-pr-comment/issues/93#issuecomment-1531415467
     I set it to a smaller value *)
  let max_comment_length = 65536 / 2
end
