module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  module Builder : module type of Terrat_vcs_event_evaluator2_builder.Make (S)

  type existing_wm =
    ( S.Api.Account.t,
      ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t

  val token : Cstruct.t -> Uuidm.t -> string

  val match_tag_queries :
    accessor:('a -> Terrat_tag_query.t) ->
    changes:Terrat_change_match3.Dirspace_config.t list ->
    'a list ->
    (Terrat_change_match3.Dirspace_config.t * (int * 'a) option) list

  val dirspaceflows_of_changes :
    'a Terrat_base_repo_config_v1.t ->
    Terrat_change_match3.Dirspace_config.t list ->
    (Terrat_change.Dirspaceflow.Workflow.t option Terrat_change.Dirspaceflow.t list, 'c) result

  val run :
    name:string ->
    eq:(existing_wm -> bool) ->
    create:
      (Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (existing_wm list, Builder.err) result Abb.Future.t) ->
    initiate:
      (existing_wm ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (Terrat_api_components.Work_manifest.t, Builder.err) result Abb.Future.t) ->
    fail:
      (existing_wm ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (unit, Builder.err) result Abb.Future.t) ->
    result:
      (existing_wm ->
      Terrat_api_components.Work_manifest_result.t ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (unit, Builder.err) result Abb.Future.t) ->
    Builder.B.State.t ->
    Builder.Bs.Fetcher.t ->
    (existing_wm list, Builder.err) result Abb.Future.t
end
