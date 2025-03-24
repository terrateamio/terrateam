(** A Flow is a sequence of steps that can make branch. A flow can be suspended and resumed, and the
    suspended state is serializable. Flow a represented as a tree, however only one path through the
    tree is ever taken. Resuming a suspended flow starts from the same step that yielded the flow.
*)

module type S = sig
  type of_string_err [@@deriving show]
  type step_err [@@deriving show]
  type t

  val to_string : t -> string
  val of_string : string -> (t, of_string_err) result
end

module type ID = sig
  type t [@@deriving show, eq]

  val to_string : t -> string
  val of_string : string -> t option
end

module Ret : sig
  type ('a, 'b, 'c) t =
    [ `Success of 'a
    | `Failure of 'b
    | `Yield of 'c
    ]
end

module Make (Fut : Abb_intf.Future.S) (Id : ID) (State : S) : sig
  type run_err =
    [ `Step_err of Id.t * State.step_err
    | `Step_exn_err of Id.t * exn * Printexc.raw_backtrace option
    ]
  [@@deriving show]

  module Yield : sig
    type of_string_err =
      [ `Decode_state_err of State.of_string_err
      | `Decode_err
      ]
    [@@deriving show]

    type t

    val state : t -> State.t
    val set_state : State.t -> t -> t
    val to_string : t -> string
    val of_string : string -> (t, [> of_string_err ]) result
  end

  module Step : sig
    (** A flow step contains an [id] and a function. The function takes a [run_data] and a [state].
        A step can succeed, returning a new state, it can file, returning an error, or it can yield,
        also returning a new state. *)
    type 'a t

    val make :
      id:Id.t -> f:('a -> State.t -> (State.t, State.step_err, State.t) Ret.t Fut.t) -> unit -> 'a t

    val id : 'a t -> Id.t
  end

  module Flow : sig
    type 'a t

    val seq : 'a t -> 'a t -> 'a t
    val action : 'a Step.t list -> 'a t

    (** Generate additional workflow given the state. Be careful with this, if anything in it yields
        it must generate the same workflow on each resume. *)
    val gen : ('a -> State.t -> 'a t) -> 'a t

    val choice :
      id:Id.t ->
      f:('a -> State.t -> (Id.t * State.t, State.step_err) result Fut.t) ->
      (Id.t * 'a t) list ->
      'a t

    (** Perform a flow after the inner flow has finished, regardless of if it is a success or
        failure. Yielding is not permitted in the [finally] flow. The result of [flow] is always
        returned regardless of the result of [finally]. *)
    val finally : id:Id.t -> 'a t -> finally:'a t -> 'a t

    (** Recover from a failure in a flow. On failure, the function [f] is called to determine which
        recover flow to choose. The failure is eaten and the flow evaluates to the result of the
        chosen recover flow. Yielding is supported in the recover flow. *)
    val recover :
      id:Id.t ->
      'a t ->
      f:('a -> State.t -> run_err -> (Id.t * State.t, State.step_err) result Fut.t) ->
      recover:(Id.t * 'a t) list ->
      'a t

    val to_yojson : 'a t -> Yojson.Safe.t
  end

  module Event : sig
    (** The [State.t] passed into [Step_end] is the same as passed in to [Step_start], this way the
        two events can be correlated if the step changes the state. *)

    type 'a t =
      | Step_start of ('a Step.t * State.t)
      | Step_end of ('a Step.t * (State.t, run_err, State.t) Ret.t * State.t)
      | Choice_start of (Id.t * State.t)
      | Choice_end of (Id.t * (Id.t * State.t, run_err) result * State.t)
      | Finally_start of (Id.t * State.t)
      | Finally_resume of (Id.t * State.t)
      | Recover_choice of (Id.t * Id.t * State.t)
      | Recover_start of (Id.t * State.t)
  end

  type 'a t

  (** Create a flow with an optional logging callback. *)
  val create : ?log:('a Event.t -> unit) -> 'a Flow.t -> 'a t

  (** [run run_data state flow] executes a flow until it finishes (successfully or fails) or yields.
      [run_data] is data that will not be serialized on a [Yield]. It is possible that this changes
      between an invocation of [run] and [resume]. *)
  val run : 'a -> State.t -> 'a t -> (State.t, run_err, Yield.t) Ret.t Fut.t

  (** Resume a flow that has yielded. *)
  val resume : 'a -> Yield.t -> 'a t -> (State.t, run_err, Yield.t) Ret.t Fut.t

  (** Create a [Yield.t] that starts at the beginning of the flow. This is useful for making a
      unified API for running and resuming , [resume] can always be called, *)
  val yield_of_state : State.t -> Yield.t
end
