(** A simple thread pool implementation. *)

type 'a t

(** Create a thread pool with the defined capacity.  [capacity] number of
    threads will be started and maintained at all times.

    @param wait a function which generates a value to wait on.  This is executed
    in the main thread. *)
val create : capacity:int -> wait:(unit -> 'a) -> 'a t

(** Add a new piece of work to the queue.  Threads will consume the work
    as they become available.

    @param f the work that will be executed in the thread.

    @param trigger the function to call with the result and a wait token to
    signal the work is complete.  If the function threw an exception, trigger is
    called with that.

    @returns the value created by the wait so the caller can setup hooks for the
    work completing. *)
val enqueue :
  'a t ->
  f:(unit -> 'b) ->
  trigger:('a -> ('b, exn * Printexc.raw_backtrace option) result -> unit) ->
  'a

(** Destroy the thread pool.  Destroy does not wait for any work executing in
    the thread pool to be finished before returning. *)
val destroy : 'a t -> unit
