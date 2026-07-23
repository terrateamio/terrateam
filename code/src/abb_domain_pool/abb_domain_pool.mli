(** A pool of worker domains that runs caller-supplied thunks.

    Workers park on a condition variable until work arrives. When a thunk completes the worker
    returns to the pool to pick up the next one; whatever cross-domain delivery the caller wants
    (e.g. pushing a completion record onto an op queue) is the caller's responsibility, baked into
    the submitted thunk. *)

type t

(** Create a pool of [capacity] worker domains. [capacity] must be positive. *)
val create : capacity:int -> t

(** Submit a thunk to be run on some worker domain. The thunk runs to completion on whichever worker
    picks it up. An exception escaping the thunk is not caught by the pool — the worker domain dies
    and [destroy] re-raises it via [Domain.join].

    If [aborted] is supplied, the caller can set it any time between submission and the worker
    popping the thunk; the worker reads the flag once after popping and silently skips the thunk if
    it is set. Aborting after the worker has started running the thunk has no effect (OCaml threads
    cannot be safely interrupted). *)
val enqueue : ?aborted:bool Atomic.t -> t -> (unit -> unit) -> unit

(** Best-effort variant of [enqueue]. Returns [true] iff a worker was idle and the thunk was placed
    on the queue (a signal was sent and that worker will pick it up). Returns [false] if every
    worker is currently busy — the thunk is {b not} queued in that case; the caller is expected to
    run the work themselves rather than wait for a worker.

    [aborted] has the same meaning as in {!enqueue}. *)
val try_enqueue : ?aborted:bool Atomic.t -> t -> (unit -> unit) -> bool

(** Signal all workers to shut down and join their domains. *)
val destroy : t -> unit
