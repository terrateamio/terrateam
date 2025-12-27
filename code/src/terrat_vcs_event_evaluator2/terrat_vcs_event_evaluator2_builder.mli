(** Builder defines all of the state, error messages, keys, and functionality to build. The usage
    is:

    1. Create a [t] using [make] with the tasks and the state.

    2. Use [eval] to execute a key and get its value or failure.

    In some cases, it may be desirable to evaluate a key using the initial state, because some
    evaluated keys needs to be invalidated. To do that, construct a new [t] with [reset] and then
    use [eval] *)
module Make (S : Terrat_vcs_provider2.S) : sig
  module Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap : module type of Keys.Hmap

  type err = Keys.err [@@deriving show]

  module B : Buildsys.S with type 'v k = 'v Hmap.key and type 'a C.t = 'a Abb.Future.t

  module Bs :
    Buildsys.T
      with type 'a k = 'a B.k
       and type key_repr = string
       and type 'a c = 'a Abb.Future.t
       and type state = B.State.t

  val rebuilder : Bs.Rebuilder.t

  module State : sig
    type t = B.State.t

    val make :
      log_id:string ->
      store:Hmap.t ->
      config:S.Api.Config.t ->
      db:Pgsql_io.t ->
      tasks:Hmap.t ->
      unit ->
      B.State.t Abb.Future.t

    val set_log_id : string -> t -> t
    val config : t -> S.Api.Config.t
    val mark_dirty : t -> 'v Bs.k -> unit
    val orig_store : t -> Hmap.t
    val set_orig_store : Hmap.t -> t -> t
    val tasks : t -> Hmap.t
    val set_tasks : Hmap.t -> t -> t

    (** If a store value exists in [s] add it to this store. Useful for constructing new stores when
        doing a nested eval call. *)
    val forward_store_value : 'v Bs.k -> t -> Hmap.t -> Hmap.t
  end

  val coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k

  val run_db :
    B.State.t ->
    f:(Pgsql_io.t -> ('a, ([> `Closed ] as 'e)) result Abb.Future.t) ->
    ('a, ([> `Closed ] as 'e)) result Abb.Future.t

  val log_id : B.State.t -> string
  val mk_log_id : request_id:string -> Uuidm.t -> string
  val eval : State.t -> 'v Bs.k -> 'v Bs.c
end
