module Api = Terrat_vcs_api_gitlab
module By_scope = Terrat_vcs_service_gitlab_scope.By_scope
module Publisher_tools = Terrat_vcs_service_gitlab_publishers.Publisher_tools
module Output = Terrat_vcs_service_gitlab_publishers.Output
module Scope = Terrat_vcs_service_gitlab_scope.Scope
module Tmpl = Terrat_vcs_service_gitlab_assets.Tmpl
module Ui = Terrat_vcs_service_gitlab_assets.Ui
module Visible_on = Terrat_base_repo_config_v1.Workflow_step.Visible_on

module S = struct
  type t = {
    account_status : Terrat_vcs_provider2.Account_status.t;
    client : Api.Client.t;
    config : Api.Config.t;
    is_layered_run : bool;
    hooks : (Scope.t * Terrat_api_components_workflow_step_output.t list) list;
    pull_request : (unit, unit) Api.Pull_request.t;
    request_id : string;
    remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
    result : Terrat_api_components_work_manifest_tf_operation_result2.t;
    work_manifest : (Api.Account.t, unit) Terrat_work_manifest3.Existing.t;
  }

  type el = {
    dirspace : Terrat_dirspace.t;
    steps : Terrat_api_components_workflow_step_output.t list;
    strategy : Terrat_vcs_comment.Strategy.t;
  }
  [@@deriving show]

  (*TODO: fix this later*)
  type comment_id = unit [@@deriving ord, show]

  module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t el = raise (Failure "nyi")
  let query_els_for_comment_id t cid = raise (Failure "nyi")
  let upsert_comment_id t els cid = Abb.Future.return (Ok ())
  let delete_comment t comment_id = raise (Failure "nyi")
  let minimize_comment t comment_id = raise (Failure "nyi")

  let post_comment t els =
    let open Abbs_future_combinators.Infix_result_monad in
    let module R2 = Terrat_api_components.Work_manifest_tf_operation_result2 in
    let gates = t.result.R2.gates in
    let by_dirspace = CCList.map (fun el -> (Scope.Dirspace el.dirspace, el.steps)) els in
    let by_scope = t.hooks @ by_dirspace in
    let body =
      Publisher_tools.create_run_output
        ~view:`Full
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
    let msg_type = "GITLAB COMMENT" in
    let open Abbs_future_combinators.Infix_result_monad in
    Api.comment_on_pull_request ~request_id t.client t.pull_request body
    >>= fun () ->
    Logs.info (fun m -> m "%s : PUBLISHED_COMMENT : %s" request_id msg_type);
    Abb.Future.return (Ok ())

  let rendered_length t els =
    let module R2 = Terrat_api_components.Work_manifest_tf_operation_result2 in
    let gates = t.result.R2.gates in
    let by_dirspace = CCList.map (fun el -> (Scope.Dirspace el.dirspace, el.steps)) els in
    let by_scope = t.hooks @ by_dirspace in
    let out =
      Publisher_tools.create_run_output
        ~view:`Full
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

  (* TODO: For testing purposes only, will change this later *)
  (* TODO: Wirte with proper templates on Tmpl later *)
  let compact el = el

  let compare_el el1 el2 =
    let module P = Terrat_vcs_service_gitlab_publishers in
    P.dirspace_compare (el1.dirspace, el1.steps) (el2.dirspace, el2.steps)

  (* Gitlab Limits it to either 1MB or 10^6 characters
     https://docs.gitlab.com/administration/instance_limits/#size-of-comments-and-descriptions-of-issues-merge-requests-and-epics
     I set it to a smaller value *)
  let max_comment_length = 1000000 / 2
end
