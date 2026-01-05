module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  module Builder : module type of Terrat_vcs_event_evaluator2_builder.Make (S)

  val run :
    name:string ->
    (Builder.Bs.state -> Builder.Bs.Fetcher.t -> ('v, Builder.err) result Abb.Future.t) ->
    Builder.Bs.key_repr list ->
    Builder.Bs.state ->
    Builder.Bs.Fetcher.t ->
    ('v, Builder.err) result Abb.Future.t

  val default_tasks : unit -> Terrat_vcs_event_evaluator2_targets.Make(S).Hmap.t
end
