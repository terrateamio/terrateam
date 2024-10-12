(** A keyed concurrent executor allows the concurrent execution of work that is
    serialized based on its derived keys.  This allows a piece of work to
    serialize across multiple dimensions.  For example, consider a system with
    users.  When renaming a user, the operation to perform the rename could have
    the new username and the old username as keys, guaranteeing no other rename
    operations interfer.

    Order is guaranteed across keys.  For example, consider a queue with 3 items
    in it with the following keys: 1) [A], 2) [A, B], 3) [B, C].  Once (1) is
    executing, (2) cannot be, however (3) could be, based purely on the
    overlapping keys.  But (2) would lock a key that (3) depends on.  Therefore,
    (3) should only run after (2).  *)

type enqueue_err = [ `Closed ] [@@deriving show]

module Make (Fut : Abb_intf.Future.S) (Key : Map.OrderedType) : sig
  type 'a t

  (** Create an executor with the specified number of slots and a function that
      knows how to create the list of keys from the work item. *)
  val create : slots:int -> ('a -> unit Fut.t) -> 'a t Fut.t

  (** Enqueue a piece of work, return immediately.  If the queue is draining,
      [enqueue] will return [`Closed].  An empty key list does not block on any
      other key, including other empty key lists. *)
  val enqueue : 'a t -> keys:Key.t list -> 'a -> (unit, [> enqueue_err ]) result Fut.t

  (** Destroy the executor immediately.  Do not wait for any executing or queued
      work to complete.  If the executor has already been destroyed, this is a
      noop. *)
  val destroy : 'a t -> unit Fut.t

  (** Prevent the queue from accepting any more work, wait for all work to
      complete (queued and in-flight), and destroy the queue.  Return when queue
      has been destroyed.  If the executor has already been destroyed, this is a
      noop. *)
  val drain_and_destroy : 'a t -> unit Fut.t
end
