let src = Logs.Src.create "abb_domain_pool"

module Logs = (val Logs.src_log src : Logs.LOG)

(* A unit of work and a flag the submitter can flip to abort it before
   a worker picks it up.  Once a worker has popped the thunk and is
   about to run it, the worker reads [aborted] once: if set, the thunk
   is silently skipped.  After the read the thunk runs unconditionally
   — OCaml threads cannot be safely interrupted mid-execution. *)
type work = {
  thunk : unit -> unit;
  aborted : bool Atomic.t;
}

type t = {
  work_queue : work Queue.t;
  mutex : Mutex.t;
  cond : Condition.t;
  shutdown : bool ref;
  (* Number of workers currently executing a user thunk.  A worker NOT counted here is either parked
     on [cond] or in the brief window between finishing a thunk and re-checking the queue (or still
     starting up) — in every one of those states it will consume queued work, so [try_enqueue] can
     safely hand off to the pool.  Only when ALL workers are inside thunks ([running = capacity]) is
     the pool genuinely saturated and unable to pick up new work.

     Using this instead of a "parked right now" count is what keeps [try_enqueue] from failing
     spuriously: under load a worker is frequently idle-but-not-yet-parked (just finished a thunk, or
     just spawned), and a "parked" count would miss it and wrongly report saturation. *)
  running : int Atomic.t;
  capacity : int;
  domains : unit Domain.t list;
}

let never_aborted = Atomic.make false

let rec worker (work_queue, mutex, cond, shutdown, running) =
  Mutex.lock mutex;
  while Queue.is_empty work_queue && not !shutdown do
    Condition.wait cond mutex
  done;
  if not !shutdown then (
    let w = Queue.pop work_queue in
    (* Count this worker as running while its thunk executes (outside the mutex).  [incr] under the
       mutex so a concurrent [try_enqueue] sees a consistent count; [decr] after the thunk. *)
    Atomic.incr running;
    Mutex.unlock mutex;
    if not (Atomic.get w.aborted) then w.thunk ();
    Atomic.decr running;
    worker (work_queue, mutex, cond, shutdown, running))
  else Mutex.unlock mutex

let spawn_workers args n =
  let domains = ref [] in
  (try
     for _ = 1 to n do
       domains := Domain.spawn (fun () -> worker args) :: !domains
     done
   with exn ->
     let _, mutex, cond, shutdown, _ = args in
     Mutex.lock mutex;
     shutdown := true;
     Condition.broadcast cond;
     Mutex.unlock mutex;
     List.iter Domain.join !domains;
     raise exn);
  !domains

let create ~capacity =
  if capacity <= 0 then
    raise (Invalid_argument (Printf.sprintf "capacity is %d, must be greater than 0" capacity));
  let work_queue = Queue.create () in
  let mutex = Mutex.create () in
  let cond = Condition.create () in
  let shutdown = ref false in
  let running = Atomic.make 0 in
  Logs.debug (fun m -> m "start : capacity=%d" capacity);
  let domains = spawn_workers (work_queue, mutex, cond, shutdown, running) capacity in
  { work_queue; mutex; cond; shutdown; running; capacity; domains }

let enqueue ?(aborted = never_aborted) t thunk =
  Mutex.lock t.mutex;
  Queue.push { thunk; aborted } t.work_queue;
  Condition.broadcast t.cond;
  Mutex.unlock t.mutex

(* Best-effort enqueue: accept the thunk iff at least one worker is not currently inside a thunk
   (i.e. [running < capacity]), meaning some worker is parked, transitioning, or starting up and will
   consume the queued work.  Returns [true] iff the thunk was placed on the queue (and a worker
   signalled).  Returns [false] only under genuine saturation — every worker is busy in a thunk — so
   the caller runs the work itself rather than queue it behind (possibly long-blocked) workload.

   [Condition.signal] wakes a parked worker; a transitioning/starting worker instead observes the
   non-empty queue on its next check, so the wake is never lost. *)
let try_enqueue ?(aborted = never_aborted) t thunk =
  Mutex.lock t.mutex;
  if Atomic.get t.running < t.capacity then (
    Queue.push { thunk; aborted } t.work_queue;
    Condition.signal t.cond;
    Mutex.unlock t.mutex;
    true)
  else (
    Mutex.unlock t.mutex;
    false)

let destroy t =
  Mutex.lock t.mutex;
  t.shutdown := true;
  Condition.broadcast t.cond;
  Mutex.unlock t.mutex;
  List.iter Domain.join t.domains
