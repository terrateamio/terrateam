module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  module Builder : module type of Terrat_vcs_event_evaluator2_builder.Make (S)
  module Wm_sm : module type of Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)

  val run :
    dest_branch_ref:S.Api.Ref.t ->
    branch_ref:S.Api.Ref.t ->
    branch:S.Api.Ref.t ->
    name:string ->
    Builder.B.State.t ->
    Builder.Bs.Fetcher.t ->
    (Wm_sm.existing_wm list, Builder.err) result Abb.Future.t
end
