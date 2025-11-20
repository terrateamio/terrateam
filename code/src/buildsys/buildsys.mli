module Error : sig
  type key_repr = string [@@deriving show]

  type t = {
    blocking : (key_repr * key_repr list) list;
    cycle : key_repr list;
    k : key_repr;
    path : key_repr list;
    running : (key_repr * key_repr list) list;
  }
  [@@deriving show]

  exception Fetch_cycle_exn of t
end

module type S = sig
  module Key_repr : sig
    type t

    val equal : t -> t -> bool
    val to_string : t -> string
  end

  type 'v k

  val key_repr_of_key : 'a k -> Key_repr.t

  module C : sig
    type 'a t

    val return : 'a -> 'a t
    val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t

    (** In case the compute model has failure, protect guarantees an un-failed compute result that
        wraps a (possibly) failed result. The inner [t] must be completely executed to continue. *)
    val protect : (unit -> 'a t) -> 'a t t
  end

  module Notify : sig
    type t

    val create : unit -> t
    val notify : t -> unit C.t
    val wait : t -> unit C.t
  end

  module State : sig
    type t

    val set_k : t -> 'v k -> 'v -> unit C.t
    val get_k : t -> 'v k -> 'v C.t
    val get_k_opt : t -> 'v k -> 'v option C.t
  end
end

module type T = sig
  type 'v k
  type key_repr
  type 'a c
  type state

  module Fetcher : sig
    type t = { fetch : 'r. 'r k -> 'r c }
  end

  module Task : sig
    type 'v t = key_repr list -> state -> Fetcher.t -> 'v c
  end

  module Tasks : sig
    type t = { get : 'v. state -> 'v k -> 'v Task.t option c }
  end

  module Rebuilder : sig
    type t = { run : 'v. state -> 'v k -> 'v -> bool c }
  end

  module St : sig
    type t

    val create : state -> t
    val get_state : t -> state
  end

  val build : Rebuilder.t -> Tasks.t -> 'v k -> St.t -> 'v c
end

module Make (M : S) :
  T
    with type 'a k = 'a M.k
     and type key_repr = M.Key_repr.t
     and type 'a c = 'a M.C.t
     and type state = M.State.t
