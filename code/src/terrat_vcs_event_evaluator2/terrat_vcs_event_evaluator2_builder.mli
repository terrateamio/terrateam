module Make (S : Terrat_vcs_provider2.S) : sig
  module Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap : module type of Keys.Hmap

  type repo_config_fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err
  [@@deriving show]

  type err =
    [ `Missing_dep_err of string
    | `Error
    | `Closed
    | repo_config_fetch_err
    | Terrat_change_match3.synthesize_config_err
    | `Suspend_eval_err of string
    | `Work_manifest_err of Uuidm.t
    | `Noop
    | Pgsql_io.err
    | Pgsql_pool.err
    | Str_template.err
    ]
  [@@deriving show]

  module B : Buildsys.S with type 'v k = 'v Hmap.key and type 'a C.t = ('a, err) result Abb.Future.t

  module Bs :
    Buildsys.T
      with type 'a k = 'a B.k
       and type 'a c = ('a, err) result Abb.Future.t
       and type state = B.State.t

  val rebuilder : Bs.Rebuilder.t

  module State : sig
    type t = B.State.t

    val make :
      log_id:string ->
      store:Hmap.t ->
      config:S.Api.Config.t ->
      db:Pgsql_io.t ->
      unit ->
      B.State.t Abb.Future.t

    val config : t -> S.Api.Config.t
    val mark_dirty : t -> 'v Bs.k -> unit
    val store : t -> Hmap.t
  end

  val coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k
  val union_tasks : Bs.Tasks.t -> Bs.Tasks.t -> Bs.Tasks.t

  val run_db :
    B.State.t ->
    f:(Pgsql_io.t -> ('a, ([> `Closed ] as 'e)) result Abb.Future.t) ->
    ('a, ([> `Closed ] as 'e)) result Abb.Future.t

  val log_id : B.State.t -> string
end
