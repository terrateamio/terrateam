module Api = Terrat_vcs_api_github
module Scope = Terrat_scope.Scope
module Visible_on = Terrat_base_repo_config_v1.Workflow_step.Visible_on

val dirspace_compare :
  Terrat_dirspace.t * Terrat_api_components.Workflow_step_output.t list ->
  Terrat_dirspace.t * Terrat_api_components.Workflow_step_output.t list ->
  int

module Comment_api : sig
  val comment_on_pull_request :
    request_id:string ->
    Api.Client.t ->
    ('a, 'b) Api.Pull_request.t ->
    string ->
    string ->
    (Api.Comment.Id.t, [> `Error ]) Abbs_future_combinators.Infix_result_monad.t

  val apply_template_and_publish :
    request_id:string ->
    Api.Client.t ->
    ('a, 'b) Api.Pull_request.t ->
    string ->
    Snabela.t ->
    Snabela.Kv.t Snabela.Kv.Map.t ->
    (Api.Comment.Id.t, [> `Error ]) Abbs_future_combinators.Infix_result_monad.t

  val apply_template_and_publish_jinja :
    request_id:string ->
    Api.Client.t ->
    ('a, 'b) Api.Pull_request.t ->
    string ->
    string ->
    Yojson.Safe.t ->
    (Api.Comment.Id.t, [> `Error ]) Abbs_future_combinators.Infix_result_monad.t
end

module Publisher_tools : sig
  val create_run_output :
    view:[> `Compact ] ->
    string ->
    [< `Active | `Disabled | `Expired | `Trial_ending of int64 > `Trial_ending ] ->
    Api.Config.t ->
    bool ->
    'a list ->
    (Scope.t, Terrat_api_components_workflow_step_output.t list) CCList.Assoc.t ->
    Terrat_api_components_gate.t list option ->
    ( Api.Account.t,
      Uuidm.t,
      'b,
      'c,
      'd,
      'e Terrat_change.Dirspaceflow.t list,
      Terrat_work_manifest3.Deny.t list,
      'f )
    Terrat_work_manifest3.t ->
    string
end
