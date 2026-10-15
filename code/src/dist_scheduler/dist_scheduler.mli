(** The kind of store error that occurred. *)
type err_kind =
  | Create
  | Fetch
  | Store
  | Update
  | Delete
  | Tx
[@@deriving show]

(** A store error: its [kind] says which operation failed, [msg] is a human-readable detail. *)
type err = {
  kind : err_kind;
  msg : string;
}
[@@deriving show]

type dist_sched_err = [ `Dist_sched_err of err ] [@@deriving show]

(** The interface a user must provide to {!Make}. *)
module type S = sig
  module Task : sig
    type 'a t
  end

  module Store : sig
    (** The type of our store of scheduler tasks. It is possible that multiple of these will be
        created at the same time within the same process. *)
    type t

    (** Representing a transaction *)
    type tx

    (** The options to pass to create *)
    type opts

    (** Type of a stored task *)
    type stored

    (** Type of a freshly minted task *)
    type minted

    (** Type of an id of a task *)
    type id

    val create : opts -> (t, [> dist_sched_err ]) result Abb.Future.t

    (** Fetch the next item. If there are no more items to fetch then return [None] *)
    val fetch_next : tx -> (stored Task.t option, [> dist_sched_err ]) result Abb.Future.t

    val destroy : t -> unit Abb.Future.t

    (** Run [f] inside a transaction. [f]'s value is returned as [Ok]; if the transaction itself
        cannot be established (e.g. no database connection), an error with kind [Tx] is returned. *)
    val tx : t -> (tx -> 'a Abb.Future.t) -> ('a, [> dist_sched_err ]) result Abb.Future.t

    module Task : sig
      val store : tx -> minted Task.t -> (stored Task.t, [> dist_sched_err ]) result Abb.Future.t
      val update : tx -> stored Task.t -> (unit, [> dist_sched_err ]) result Abb.Future.t
      val delete : tx -> stored Task.t -> (unit, [> dist_sched_err ]) result Abb.Future.t
      val fetch : tx -> id -> (stored Task.t option, [> dist_sched_err ]) result Abb.Future.t
    end
  end

  val run : Store.tx -> Store.stored Task.t -> unit Abb.Future.t
end

module type T = sig
  (** The scheduler type *)
  type t

  type opts
  type id
  type stored
  type minted

  (** Create a new scheduler. [wait] is the function to call between iterations of the scheduler
      that triggers when it is time for the next iteration to happen. *)
  val start : name:string -> wait:(unit -> unit Abb.Future.t) -> opts -> t Abb.Future.t

  val stop : t -> unit Abb.Future.t

  (** Store a freshly minted task, returning the stored representation. Runs in its own transaction.
  *)
  val store : t -> minted -> (stored, [> dist_sched_err ]) result Abb.Future.t

  (** Update an existing stored task. Runs in its own transaction. *)
  val update : t -> stored -> (unit, [> dist_sched_err ]) result Abb.Future.t

  (** Delete an existing stored task. Runs in its own transaction. *)
  val delete : t -> stored -> (unit, [> dist_sched_err ]) result Abb.Future.t

  (** Fetch a stored task by its id. Returns [None] if no such task exists. Runs in its own
      transaction. *)
  val fetch : t -> id -> (stored option, [> dist_sched_err ]) result Abb.Future.t
end

module Make (S : S) :
  T
    with type opts = S.Store.opts
     and type id = S.Store.id
     and type minted = S.Store.minted S.Task.t
     and type stored = S.Store.stored S.Task.t
