(* The architecture of this scheduler — operation flow, pinned vs
   unpinned task execution, worker-pool fallback, and the cross-domain
   safety model — is described in RFD 675.  Read it before making
   changes here. *)

module List = ListLabels
module Sys_stdlib = Sys
module Unix = UnixLabels

module Native = struct
  type t = Unix.file_descr
end

external unsafe_int_of_file_descr : Unix.file_descr -> int = "%identity"

let sec_ns = Mtime.Span.(to_float_ns s)

(* Per-task callback-serialization context, shared between the task's
   [task_data] (so call sites of async ops can find it) and the [Op.t]
   records they submit (so the dispatcher can serialize callbacks and
   run [post_callback] after each).  Defined above [Op] because the
   dispatch code below depends on it.

   The structure is a lock-free mailbox of pending callbacks plus a
   CAS gate ([draining]) that ensures at most one worker is processing
   a given task's callbacks at any time.  No mutex — coordination is
   purely message-passing through a Saturn MPSC queue.

   Producers (the dispatcher's [run_callback] when an async op fires
   for the task) push their callback thunk onto [mailbox] and then
   attempt to claim [draining] via CAS [false → true].  If the CAS
   wins, the producer dispatches a worker domain to drain; if the CAS
   loses, the producer trusts the already-active drainer to pick up
   the new entry.

   The drainer pops thunks until [pop_opt] returns [None], then flips
   [draining] back to [false] and re-checks the queue for entries
   pushed during the release window; if it finds one and wins a fresh
   CAS, it loops again, otherwise the next producer will dispatch a
   fresh drainer. *)
module Task_ctx = struct
  type t = {
    mailbox : (unit -> unit) Saturn.Single_consumer_queue.t;
    draining : bool Atomic.t;
    post_callback : unit -> unit;
  }
end

(* Handle: the live libuv handle, if any, backing an in-flight op.
   Held in [Op.op_state] so an abort knows what to tear down. *)
module Handle = struct
  type t =
    | None
    | Timer of Luv.Timer.t
    | Poll of Luv.Poll.t
end

(* Op: data describing an async operation that the scheduler must perform on
   the loop domain.  Submission goes through [Op_queue.submit], which is safe
   from any domain.  See agent_docs / the design plan for the full model. *)
module Op = struct
  type op_state = {
    aborted : bool Atomic.t;
    (* Mutated only on the scheduler (loop) domain. *)
    mutable handle : Handle.t;
  }

  type body =
    | Sleep of {
        ms : int;
        on_fire : unit -> unit;
      }
    | Poll of {
        fd : Unix.file_descr;
        events : Luv.Poll.Event.t list;
        on_event : (Luv.Poll.Event.t list, Luv.Error.t) result -> unit;
      }
    | Close_fd of Unix.file_descr  (** deferred [Unix.close] (replaces the zero-ms timer trick) *)
    | Abort of op_state  (** worker-side abort hand-off *)
    | Run of (unit -> unit)
        (** generic "run this on the scheduler"; used as the worker → scheduler completion path for
            pooled work (see [Op.Thread]). *)
    | Thread : {
        f : unit -> 'a;
        on_done : ('a, exn * Printexc.raw_backtrace option) result -> unit;
      }
        -> body
        (** Run [f] on a worker domain. When [f] completes, deliver [on_done result] back to the
            scheduler via an [Op.Run]. *)

  type t = {
    state : op_state;
    body : body;
    (* When [Some ctx] the dispatcher pushes the callback onto
       [ctx.mailbox] and races to claim [ctx.draining]; the winning
       worker drains the mailbox, running each thunk followed by
       [ctx.post_callback].  When [None] the callback runs
       inline on the scheduler domain (the pinned case). *)
    unpinned_ctx : Task_ctx.t option;
  }
end

(* El is short for Event Loop *)
module El = struct
  type task_data = {
    task_id : int;
    task_name : string option;
    unpinned : Task_ctx.t option;
  }

  type t = {
    loop : Luv.Loop.t;
    loop_domain : Domain.id;
    mutable curr_time : float;
    mutable mono_time : Mtime.span;
    check : Luv.Check.t;
    thread_pool : Abb_domain_pool.t;
    task_counter : int Atomic.t;
    op_queue : Op.t Saturn.Single_consumer_queue.t;
    op_async : Luv.Async.t;
  }

  (* The scheduler's [Abb_fut] state payload.  It carries the event loop [el] plus the owning
     [Task_ctx] of the task this state belongs to: [None] for the root/loop state and for pinned
     tasks (their resumes run inline on the loop), [Some ctx] for an unpinned task's [worker_state].
     Routing of a resume/callback is read from this (via {!unpinned_of_state}) at the moment the
     future is driven -- the state is the ground truth of which task owns the drive -- rather than
     from the per-domain chain-data DLS at construction time. *)
  type sched = {
    el : t;
    owning : Task_ctx.t option;
  }

  type task_data_ = task_data
  type sched_ = sched

  module Future = Abb_fut.Make (struct
    type data = task_data_

    let zero_data = { task_id = 0; task_name = None; unpinned = None }

    type t = sched_
  end)

  (* Install a richer chain-data printer for [Abb_fut]'s debug build so the
     cross-domain race report includes task identity.  No-op in release. *)
  let () =
    Future.set_debug_data_pp (fun d ->
        Printf.sprintf
          "task_id=%d task_name=%s unpinned=%s"
          d.task_id
          (CCOption.get_or ~default:"<anon>" d.task_name)
          (match d.unpinned with
          | None -> "false"
          | Some _ -> "true"))
end

(* Op_queue: submission + dispatcher.  All [Luv.<Handle>.init]/[start]/[stop]/
   [close] for queued ops happens inside [dispatch], which only runs on the
   loop domain (it is the body of [op_async]'s callback). *)
module Op_queue = struct
  let cleanup_handle state =
    (match state.Op.handle with
    | Handle.None -> ()
    | Handle.Timer t ->
        ignore (Luv.Timer.stop t);
        Luv.Handle.close t CCFun.id
    | Handle.Poll p ->
        ignore (Luv.Poll.stop p);
        Luv.Handle.close p CCFun.id);
    state.Op.handle <- Handle.None

  let submit el op =
    Saturn.Single_consumer_queue.push el.El.op_queue op;
    ignore (Luv.Async.send el.El.op_async)

  (* Drain an unpinned task's mailbox.  Pop thunks one at a time,
     running [thunk] then [post_callback] after each.  When the
     queue is empty, release the [draining] gate and re-check the
     queue (lost-wakeup guard) — if a producer pushed during our
     release and we win a fresh CAS, recurse; otherwise exit and let
     that producer's dispatched drainer handle it.

     Exceptions from [thunk] / [post_callback] propagate.  Pool's
     worker prints them to stderr before re-raising, then the worker
     domain dies — visible failure beats silent corruption. *)
  let rec drain_mailbox ctx =
    match Saturn.Single_consumer_queue.pop_opt ctx.Task_ctx.mailbox with
    | Some thunk ->
        thunk ();
        ctx.Task_ctx.post_callback ();
        drain_mailbox ctx
    | None ->
        Atomic.set ctx.Task_ctx.draining false;
        if
          (not (Saturn.Single_consumer_queue.is_empty ctx.Task_ctx.mailbox))
          && Atomic.compare_and_set ctx.Task_ctx.draining false true
        then drain_mailbox ctx

  (* Run a task callback (on_fire / on_event / Op.Run thunk) according to
     its pinned/unpinned policy.  Pinned: run inline on the scheduler.
     Unpinned: push onto the task's mailbox; if no drainer is currently
     active (CAS [draining] false → true wins), dispatch a worker to
     drain.  Otherwise the active drainer will pick up our push. *)
  let run_callback el op thunk =
    match op.Op.unpinned_ctx with
    | None -> thunk ()
    | Some ctx ->
        Saturn.Single_consumer_queue.push ctx.Task_ctx.mailbox thunk;
        if Atomic.compare_and_set ctx.Task_ctx.draining false true then
          if not (Abb_domain_pool.try_enqueue el.El.thread_pool (fun () -> drain_mailbox ctx)) then
            (* No worker is idle — pool is saturated, likely with
               [Thread.run] payloads.  Drain on the loop domain rather
               than queue behind them.  Unpinned tasks are best-effort
               parallel: when no worker is free they degrade to running
               on the scheduler. *)
            drain_mailbox ctx

  let dispatch el op =
    let s = op.Op.state in
    match op.Op.body with
    | Op.Abort _ -> cleanup_handle s
    | Op.Close_fd fd -> ( try Unix.close fd with _ -> ())
    | Op.Run f -> run_callback el op f
    | Op.Thread { f; on_done } ->
        (* Two abort checks, mirroring the [Op.Sleep] / [Op.Poll] pattern:
           - Here, before submitting to the pool: if abort beat dispatch,
             skip enqueue entirely.
           - In the pool worker, after popping but before running [f]:
             if abort fired while the thunk was queued, skip it.
           A thread that has already started running cannot be stopped
           — that's [on_done]'s job to suppress the result. *)
        if Atomic.get s.Op.aborted then ()
        else
          Abb_domain_pool.enqueue ~aborted:s.Op.aborted el.El.thread_pool (fun () ->
              let result =
                try Ok (f ()) with exn -> Error (exn, Some (Printexc.get_raw_backtrace ()))
              in
              submit
                el
                {
                  Op.state = { Op.aborted = Atomic.make false; handle = Handle.None };
                  body = Op.Run (fun () -> on_done result);
                  unpinned_ctx = op.Op.unpinned_ctx;
                })
    | Op.Sleep { ms; on_fire } ->
        if Atomic.get s.Op.aborted then ()
        else
          let timer = Luv.Timer.init ~loop:el.El.loop () |> Result.get_ok in
          s.Op.handle <- Handle.Timer timer;
          ignore
            (Luv.Timer.start timer ms (fun () ->
                 let aborted = Atomic.get s.Op.aborted in
                 cleanup_handle s;
                 if not aborted then run_callback el op on_fire)
            |> Result.get_ok)
    | Op.Poll { fd; events; on_event } ->
        if Atomic.get s.Op.aborted then ()
        else
          let poll =
            Luv.Poll.init ~loop:el.El.loop (unsafe_int_of_file_descr fd) |> Result.get_ok
          in
          s.Op.handle <- Handle.Poll poll;
          (* All current poll sites are one-shot — they retry the syscall
             and either succeed or re-arm a fresh poll.  Stop+close inside
             the libuv callback so a stray fd-readable doesn't fire us
             twice. *)
          Luv.Poll.start poll events (fun result ->
              let aborted = Atomic.get s.Op.aborted in
              cleanup_handle s;
              if not aborted then run_callback el op (fun () -> on_event result))

  let drain el =
    let rec loop () =
      CCOption.iter
        (fun op ->
          dispatch el op;
          loop ())
        (Saturn.Single_consumer_queue.pop_opt el.El.op_queue)
    in
    loop ()
end

module El_setup = struct
  let create_el ?thread_pool_size () =
    let pool_size =
      CCInt.max 2 (CCOption.get_or ~default:(Domain.recommended_domain_count ()) thread_pool_size)
    in
    let loop = Luv.Loop.init () |> Result.get_ok in
    let check = Luv.Check.init ~loop () |> Result.get_ok in
    let op_queue = Saturn.Single_consumer_queue.create () in
    let el_ref = ref None in
    let op_async =
      Luv.Async.init ~loop (fun _ -> CCOption.iter Op_queue.drain !el_ref) |> Result.get_ok
    in
    let t =
      {
        El.loop;
        loop_domain = Domain.self ();
        curr_time = Unix.gettimeofday ();
        mono_time = Mtime_clock.elapsed ();
        check;
        thread_pool = Abb_domain_pool.create ~capacity:pool_size;
        task_counter = Atomic.make 1;
        op_queue;
        op_async;
      }
    in
    el_ref := Some t;
    ignore
      (Luv.Check.start t.El.check (fun () ->
           t.El.curr_time <- Unix.gettimeofday ();
           t.El.mono_time <- Mtime_clock.elapsed ())
      |> Result.get_ok);
    t

  let destroy_el t =
    Abb_domain_pool.destroy t.El.thread_pool;
    Luv.Handle.close t.El.op_async CCFun.id;
    ignore (Luv.Check.stop t.El.check);
    Luv.Handle.close t.El.check CCFun.id;
    (* Run the side-effecting cleanup ops still queued when the loop stopped.
       We must NOT dispatch [Run]/[Sleep]/[Poll]/[Thread] -- those would arm
       fresh [Luv.Timer]/[Luv.Poll] handles whose callbacks can never fire on
       the stopped loop, and the open handles would keep [Luv.Loop.close] from
       succeeding (leaking the loop).  But [Close_fd] (a deferred [Unix.close]
       for an already-closed file/socket) and [Abort] (which [cleanup_handle]s
       an armed handle) MUST run, or they leak the fd / leave the handle open
       -- the latter also failing [Loop.close] with [EBUSY]. *)
    let rec drain () =
      CCOption.iter
        (fun op ->
          (match op.Op.body with
          | Op.Close_fd fd -> ( try Unix.close fd with _ -> ())
          | Op.Abort _ -> Op_queue.cleanup_handle op.Op.state
          | Op.Run _ | Op.Sleep _ | Op.Poll _ | Op.Thread _ -> ());
          drain ())
        (Saturn.Single_consumer_queue.pop_opt t.El.op_queue)
    in
    drain ();
    (* Tick (bounded) so libuv invokes the close callbacks for the handles we
       just stopped; [run] returns [true] while any remain active. *)
    let rec settle n =
      if n > 0 && Luv.Loop.run ~loop:t.El.loop ~mode:`NOWAIT () then settle (n - 1)
    in
    settle 1000;
    ignore (Luv.Loop.close t.El.loop)
end

(* Build an abort closure that flips [state.aborted] and tears the live
   handle down.  Must be called from the same domain that hosts the
   aborted Future's State; for pinned Tasks (everything in this phase)
   that is always the scheduler domain, so we can call [cleanup_handle]
   directly. *)
let abort_of el state () =
  Atomic.set state.Op.aborted true;
  if Domain.self () = el.El.loop_domain then Op_queue.cleanup_handle state
  else Op_queue.submit el { Op.state; body = Op.Abort state; unpinned_ctx = None };
  El.Future.return ()

(* The event loop carried by a run state. *)
let el_of s = (Abb_fut.State.state s).El.el

(* The owning [Task_ctx] of the task that owns this run state: [Some ctx] for an unpinned task's
   [worker_state], [None] for the root/loop state and pinned tasks.  Read inside a
   [Future.with_state] closure (at the moment the future is driven) to route a resume/callback to the
   owning task's serialization gate -- this is the ground truth of who drives the state, replacing the
   eager chain-data DLS read that could go stale across the construction->drive gap. *)
let unpinned_of_state s = (Abb_fut.State.state s).El.owning

(* Helper: submit a one-shot Poll op for [fd] with [events] and resolve a
   fresh promise with the value produced by [retry] when the poll fires.
   Captures the [Future.with_state] caller's [s] so [run_with_state] can
   advance the promise without crossing domains.  Returns a [(s, fut)]
   pair shaped for [Future.with_state].

   The poll's [unpinned_ctx] is read from [s] (the run state being driven), so the callback is
   routed to the owning task's gate regardless of where the surrounding op was constructed. *)
let with_poll s ~fd ~events ~retry =
  let el = el_of s in
  let state = { Op.aborted = Atomic.make false; handle = Handle.None } in
  let p = El.Future.Promise.create ~abort:(abort_of el state) () in
  let on_event _result =
    let v = retry () in
    ignore (El.Future.run_with_state (El.Future.Promise.set p v) s)
  in
  let body = Op.Poll { fd; events; on_event } in
  Op_queue.submit el { Op.state; body; unpinned_ctx = unpinned_of_state s };
  (s, El.Future.Promise.future p)

module Future = El.Future

module Scheduler = struct
  type t = El.sched Abb_fut.State.t

  let capabilities = [ `Multi_domain ]

  let create ?thread_pool_size ?exec_duration:_ () =
    Abb_fut.State.create { El.el = El_setup.create_el ?thread_pool_size (); owning = None }

  let destroy t = El_setup.destroy_el (el_of t)

  let run t f =
    ignore Sys.(signal sigpipe Signal_ignore);
    let ret = f () in
    let t = Future.run_with_state ret t in
    match Future.state ret with
    | (`Det _ | `Aborted | `Exn _) as r -> (t, r)
    | `Undet -> (
        (* Stop the loop when [ret] reaches ANY terminal state.  A plain
           [ret >>= fun _ -> ...] only fires on [`Det]; if [ret] resolves to
           [`Exn] (a failed assertion / raised exception) or [`Aborted], the
           bind short-circuits and [Luv.Loop.stop] is never called, so
           [Luv.Loop.run] blocks forever.  [await_bind] fires its callback on
           [`Det]/[`Aborted]/[`Exn] alike. *)
        let stopper =
          Future.await_bind
            (fun _ ->
              Future.with_state (fun s ->
                  let el = el_of s in
                  Luv.Loop.stop el.El.loop;
                  (s, Future.return ())))
            ret
        in
        let t = Future.run_with_state stopper t in
        let el = el_of t in
        ignore (Luv.Loop.run ~loop:el.El.loop ());
        match Future.state ret with
        | (`Det _ | `Aborted | `Exn _) as r -> (t, r)
        | `Undet -> assert false)

  let run_with_state ?thread_pool_size ?exec_duration:_ f =
    let t = create ?thread_pool_size () in
    let t, r = run t f in
    destroy t;
    r
end

(* Bounded MPSC channel.

   Architecture: lock-free [Saturn.Bounded_queue] for the buffer + the
   scheduler as the coordinator-of-last-resort for slow paths.

   - Fast path enqueue: [Saturn.Bounded_queue.try_push] + a cheap atomic
     read of [parked_dequeue_present].  If the atomic says no consumer
     is parked, return immediately with no scheduler involvement.

   - Fast path dequeue: [Saturn.Bounded_queue.pop_opt] + a cheap atomic
     read of [parked_enqueue_count].  Symmetric.

   - Slow paths (full buffer for producer, empty buffer for consumer,
     wake-a-parked-counterparty for hot paths) submit an [Op.Run] to
     the scheduler.  The slow-path thunk runs on the loop domain, which
     means parked-list manipulation is naturally serialized — no mutex
     needed.  Each slow-path thunk re-checks the buffer state on the
     scheduler before parking, which closes any lost-wakeup race that
     might exist between the lock-free fast-path read and the parking
     decision. *)
module Chan = struct
  type 'a parked_enqueue = {
    pe_value : 'a;
    pe_promise : (unit, [ `Chan_closed ]) result Future.Promise.t;
    pe_state : El.sched Abb_fut.State.t;
    pe_aborted : bool Atomic.t;
  }

  type 'a parked_dequeue = {
    pd_promise : ('a, [ `Chan_closed ]) result Future.Promise.t;
    pd_state : El.sched Abb_fut.State.t;
    pd_aborted : bool Atomic.t;
  }

  type 'a t = {
    buffer : 'a Saturn.Bounded_queue.t;
    mutable parked_dequeue : 'a parked_dequeue option;
    parked_enqueues : 'a parked_enqueue Queue.t;
    parked_dequeue_present : bool Atomic.t;
    parked_enqueue_count : int Atomic.t;
    closed : bool Atomic.t;
  }

  let create ~capacity () =
    if capacity < 1 then
      raise (Invalid_argument (Printf.sprintf "Chan.create: capacity is %d, must be >= 1" capacity));
    {
      buffer = Saturn.Bounded_queue.create ~capacity ();
      parked_dequeue = None;
      parked_enqueues = Queue.create ();
      parked_dequeue_present = Atomic.make false;
      parked_enqueue_count = Atomic.make 0;
      closed = Atomic.make false;
    }

  let deliver el ~unpinned_ctx thunk =
    Op_queue.submit
      el
      {
        Op.state = { Op.aborted = Atomic.make false; handle = Handle.None };
        body = Op.Run thunk;
        unpinned_ctx;
      }

  let on_scheduler el thunk =
    Op_queue.submit
      el
      {
        Op.state = { Op.aborted = Atomic.make false; handle = Handle.None };
        body = Op.Run thunk;
        unpinned_ctx = None;
      }

  (* Producer-side wake of the parked consumer.  Runs on the loop domain.
     The buffer may have been drained by a concurrent fast-path [recv]
     between the producer push and this op firing, so the [None] branch
     is reachable on an open channel.  In that case re-park [pd] rather
     than spuriously failing the consumer with [Chan_closed].

     The buffer pop and the re-park decision both touch loop-domain-only
     state ([ch.parked_dequeue]) and must run here, on the loop -- NOT
     inside the [deliver] thunk, which executes on the consumer's domain
     (a worker, for an unpinned consumer) and would race the loop's own
     accesses to the non-atomic [parked_dequeue] field, dropping the
     wakeup and deadlocking.  Only the promise resolution is handed to the
     consumer's domain via [deliver]; this is sound because the channel is
     single-consumer, so no other dequeuer can race the value we popped. *)
  let rec wake_parked_dequeue el ch =
    Option.iter
      (fun pd ->
        ch.parked_dequeue <- None;
        Atomic.set ch.parked_dequeue_present false;
        if not (Atomic.get pd.pd_aborted) then
          match Saturn.Bounded_queue.pop_opt ch.buffer with
          | Some v ->
              (* Popping freed a buffer slot; a parked producer may be waiting for it.  Wake one
                 enqueuer via a fresh [on_scheduler] op (rather than recursing inline) so a long run
                 of hand-offs stays iterative through the op queue instead of growing the stack.
                 Without this wake, a sender parked while the buffer was full is never moved in once
                 this pop empties it -- a lost wakeup / deadlock. *)
              if Atomic.get ch.parked_enqueue_count > 0 then
                on_scheduler el (fun () -> wake_one_parked_enqueue el ch);
              deliver el ~unpinned_ctx:(unpinned_of_state pd.pd_state) (fun () ->
                  ignore
                    (Future.run_with_state (Future.Promise.set pd.pd_promise (Ok v)) pd.pd_state))
          | None when Atomic.get ch.closed ->
              deliver el ~unpinned_ctx:(unpinned_of_state pd.pd_state) (fun () ->
                  ignore
                    (Future.run_with_state
                       (Future.Promise.set pd.pd_promise (Error `Chan_closed))
                       pd.pd_state))
          | None ->
              ch.parked_dequeue <- Some pd;
              Atomic.set ch.parked_dequeue_present true)
      ch.parked_dequeue

  (* Move one parked enqueuer's value into the buffer.  Runs on the loop
     domain, so [parked_enqueues] is touched single-threaded.

     The [pe] is removed from the queue — and [parked_enqueue_count]
     decremented — only once its value is actually in the buffer (or the
     channel is closed).  An un-satisfiable [pe] (buffer full again) is
     left in place with its count intact, so the next [recv] that frees
     a slot still observes a waiter and retries.  An earlier version
     removed the [pe] up front and re-parked it through a separate op
     when the push failed; that left a window in which
     [parked_enqueue_count] read zero while an enqueuer still needed
     waking, and a [recv] freeing a slot in that window lost the
     wakeup. *)
  and wake_one_parked_enqueue el ch =
    match Queue.peek_opt ch.parked_enqueues with
    | None -> ()
    | Some pe when Atomic.get pe.pe_aborted ->
        (* Abandoned send: drop it and try the next waiter. *)
        ignore (Queue.take_opt ch.parked_enqueues);
        Atomic.decr ch.parked_enqueue_count;
        wake_one_parked_enqueue el ch
    | Some pe ->
        if Saturn.Bounded_queue.try_push ch.buffer pe.pe_value then (
          ignore (Queue.take_opt ch.parked_enqueues);
          Atomic.decr ch.parked_enqueue_count;
          (* This push filled a buffer slot; a parked consumer may be waiting for a value.  Mirror
             the slot-freeing wake in [wake_parked_dequeue]: hand the value to a parked dequeuer.  We
             already run on the loop, so call directly.  Without this, a consumer that parked while
             the buffer was empty is never handed the value this push just made available. *)
          if Atomic.get ch.parked_dequeue_present then wake_parked_dequeue el ch;
          deliver el ~unpinned_ctx:(unpinned_of_state pe.pe_state) (fun () ->
              ignore (Future.run_with_state (Future.Promise.set pe.pe_promise (Ok ())) pe.pe_state)))
        else if Atomic.get ch.closed then (
          ignore (Queue.take_opt ch.parked_enqueues);
          Atomic.decr ch.parked_enqueue_count;
          deliver el ~unpinned_ctx:(unpinned_of_state pe.pe_state) (fun () ->
              ignore
                (Future.run_with_state
                   (Future.Promise.set pe.pe_promise (Error `Chan_closed))
                   pe.pe_state)))
  (* else: buffer full and open — leave [pe] parked, count intact. *)

  (* Producer fast path.  No scheduler involvement when buffer not full
     AND no consumer parked.  If a consumer is hinted parked, submit one
     [Op.Run] to wake them. *)
  let send (type a) (ch : a t) (v : a) : (unit, [> `Chan_closed ]) result Future.t =
    let f =
      Future.with_state (fun s ->
          let el = el_of s in
          if Atomic.get ch.closed then (s, Future.return (Error `Chan_closed))
          else if Saturn.Bounded_queue.try_push ch.buffer v then (
            if Atomic.get ch.parked_dequeue_present then
              on_scheduler el (fun () -> wake_parked_dequeue el ch);
            (s, Future.return (Ok ())))
          else
            let aborted = Atomic.make false in
            let p =
              Future.Promise.create
                ~abort:(fun () ->
                  Atomic.set aborted true;
                  Future.return ())
                ()
            in
            let pe = { pe_value = v; pe_promise = p; pe_state = s; pe_aborted = aborted } in
            (* Resolve the caller's promise back on the caller's domain
               via [deliver].  Calling [Future.run_with_state] inline here
               would advance the caller's [State.t] from the loop domain
               and trip the [ABB_FUT_DEBUG] owner-CAS for unpinned
               callers. *)
            let resolve_caller result =
              deliver el ~unpinned_ctx:(unpinned_of_state s) (fun () ->
                  ignore (Future.run_with_state (Future.Promise.set p result) s))
            in
            on_scheduler el (fun () ->
                if Atomic.get ch.closed then resolve_caller (Error `Chan_closed)
                else if Saturn.Bounded_queue.try_push ch.buffer v then (
                  resolve_caller (Ok ());
                  if Atomic.get ch.parked_dequeue_present then wake_parked_dequeue el ch)
                else (
                  Queue.push pe ch.parked_enqueues;
                  Atomic.incr ch.parked_enqueue_count;
                  (* Close the park-time TOCTOU: a [recv] may free a slot (and read
                     [parked_enqueue_count] as still 0, so skip its wake) between the [try_push] above
                     and this count being published.  Now that the enqueuer is visible, try to move it
                     in — a no-op if the buffer is genuinely full, otherwise it fills the freed slot
                     (and hands a value to any parked consumer). *)
                  wake_one_parked_enqueue el ch));
            (s, Future.Promise.future p))
    in
    (f : (unit, [ `Chan_closed ]) result Future.t :> (unit, [> `Chan_closed ]) result Future.t)

  (* Consumer fast path.  Mirror of send. *)
  let recv (type a) (ch : a t) : (a, [> `Chan_closed ]) result Future.t =
    let f =
      Future.with_state (fun s ->
          let el = el_of s in
          match Saturn.Bounded_queue.pop_opt ch.buffer with
          | Some v ->
              if Atomic.get ch.parked_enqueue_count > 0 then
                on_scheduler el (fun () -> wake_one_parked_enqueue el ch);
              (s, Future.return (Ok v))
          | None ->
              if Atomic.get ch.closed then (s, Future.return (Error `Chan_closed))
              else
                let aborted = Atomic.make false in
                let p =
                  Future.Promise.create
                    ~abort:(fun () ->
                      Atomic.set aborted true;
                      Future.return ())
                    ()
                in
                let pd = { pd_promise = p; pd_state = s; pd_aborted = aborted } in
                (* Same rationale as the send slow path: resolve through
                   [deliver] so an unpinned caller's [State.t] is not
                   advanced from the loop domain. *)
                let resolve_caller result =
                  deliver el ~unpinned_ctx:(unpinned_of_state s) (fun () ->
                      ignore (Future.run_with_state (Future.Promise.set p result) s))
                in
                on_scheduler el (fun () ->
                    match Saturn.Bounded_queue.pop_opt ch.buffer with
                    | Some v ->
                        resolve_caller (Ok v);
                        if Atomic.get ch.parked_enqueue_count > 0 then wake_one_parked_enqueue el ch
                    | None ->
                        if Atomic.get ch.closed then resolve_caller (Error `Chan_closed)
                        else (
                          ch.parked_dequeue <- Some pd;
                          Atomic.set ch.parked_dequeue_present true;
                          (* Close the park-time TOCTOU: a [send] may push (and read
                             [parked_dequeue_present] as still false, so skip its wake) between the
                             [pop_opt] above and this flag being published.  Now that the flag is set,
                             re-check.  Take any value directly (clearing [pd] first so the
                             enqueuer-wake below cannot also resolve it); otherwise a parked enqueuer
                             can fill the still-empty buffer and the resulting wake hands it to [pd]. *)
                          match Saturn.Bounded_queue.pop_opt ch.buffer with
                          | Some v ->
                              ch.parked_dequeue <- None;
                              Atomic.set ch.parked_dequeue_present false;
                              resolve_caller (Ok v);
                              if Atomic.get ch.parked_enqueue_count > 0 then
                                wake_one_parked_enqueue el ch
                          | None ->
                              if Atomic.get ch.parked_enqueue_count > 0 then
                                wake_one_parked_enqueue el ch));
                (s, Future.Promise.future p))
    in
    (f : (a, [ `Chan_closed ]) result Future.t :> (a, [> `Chan_closed ]) result Future.t)

  let close (type a) (ch : a t) =
    if Atomic.compare_and_set ch.closed false true then
      let drain_one_pe (pe : a parked_enqueue) =
        let el = el_of pe.pe_state in
        deliver el ~unpinned_ctx:(unpinned_of_state pe.pe_state) (fun () ->
            if not (Atomic.get pe.pe_aborted) then
              ignore
                (Future.run_with_state
                   (Future.Promise.set pe.pe_promise (Error `Chan_closed))
                   pe.pe_state))
      in
      let drain_one_pd (pd : a parked_dequeue) =
        let el = el_of pd.pd_state in
        deliver el ~unpinned_ctx:(unpinned_of_state pd.pd_state) (fun () ->
            if not (Atomic.get pd.pd_aborted) then
              match Saturn.Bounded_queue.pop_opt ch.buffer with
              | Some v ->
                  ignore
                    (Future.run_with_state (Future.Promise.set pd.pd_promise (Ok v)) pd.pd_state)
              | None ->
                  ignore
                    (Future.run_with_state
                       (Future.Promise.set pd.pd_promise (Error `Chan_closed))
                       pd.pd_state))
      in
      let pe_opt = Queue.peek_opt ch.parked_enqueues in
      let el_opt =
        match pe_opt with
        | Some pe -> Some (el_of pe.pe_state)
        | None -> (
            match ch.parked_dequeue with
            | Some pd -> Some (el_of pd.pd_state)
            | None -> None)
      in
      Option.iter
        (fun el ->
          on_scheduler el (fun () ->
              Queue.iter (fun pe -> drain_one_pe pe) ch.parked_enqueues;
              Queue.clear ch.parked_enqueues;
              Atomic.set ch.parked_enqueue_count 0;
              Option.iter (fun pd -> drain_one_pd pd) ch.parked_dequeue;
              ch.parked_dequeue <- None;
              Atomic.set ch.parked_dequeue_present false))
        el_opt
end

module Task = struct
  let id () =
    let open Future.Infix_monad in
    Future.get_data () >>| fun d -> d.El.task_id

  let name () =
    let open Future.Infix_monad in
    Future.get_data () >>| fun d -> d.El.task_name

  (* Run a Task with [~pinned:false].  Body runs on a worker; callbacks
     dispatch through the pool serialized by a per-task lock; the outer
     Future returned to the caller is set via [Op.Run] when the inner
     chain reaches a terminal state. *)
  (* Wire format for the cross-domain result hand-off.  The worker side
     observes the inner Future's terminal state and serializes it into a
     [task_wire] value, which is delivered to the scheduler-side awaiter
     via a single-element [Chan]. *)
  type 'a task_wire =
    | Tw_det of 'a
    | Tw_aborted
    | Tw_exn of exn * Printexc.raw_backtrace option

  let run_unpinned (type a) ?name ~outer_data (f : unit -> a Future.t) s =
    let outer_s = s in
    let el = el_of s in
    let new_id = Atomic.fetch_and_add el.El.task_counter 1 in
    (* Cross-domain rendezvous channel.  Capacity 1: the worker enqueues
       exactly one terminal state, the scheduler-side awaiter dequeues
       it and converts to the appropriate Future state. *)
    let result_ch : a task_wire Chan.t = Chan.create ~capacity:1 () in
    let inner_fut_ref = ref None in
    let worker_state_ref = ref None in
    (* CAS-once gate: post_callback may fire after every chain advance,
       but we want exactly one delivery.  After the first observed
       terminal state we mark [delivered] and enqueue. *)
    let delivered = Atomic.make false in
    let try_deliver wire =
      if Atomic.compare_and_set delivered false true then
        match !worker_state_ref with
        | None -> ()
        | Some ws ->
            (* Drive the [Chan.send] future on the worker's state.
               Capacity 1, fresh channel: fast path always succeeds, so
               run_with_state determines the future synchronously. *)
            ignore (Future.run_with_state (Chan.send result_ch wire) ws)
    in
    let post_callback () =
      match !inner_fut_ref with
      | None -> ()
      | Some inner -> (
          match Future.state inner with
          | `Undet -> ()
          | `Det v -> try_deliver (Tw_det v)
          | `Aborted -> try_deliver Tw_aborted
          | `Exn (e, bt) -> try_deliver (Tw_exn (e, bt)))
    in
    let ctx =
      {
        Task_ctx.mailbox = Saturn.Single_consumer_queue.create ();
        (* [body] is the first drainer — claim eagerly so concurrent
           [run_callback]s queue up behind it. *)
        draining = Atomic.make true;
        post_callback;
      }
    in
    let body () =
      let worker_state = Abb_fut.State.create { El.el; owning = Some ctx } in
      worker_state_ref := Some worker_state;
      let inner =
        let open Future.Infix_monad in
        Future.set_data { El.task_id = new_id; task_name = name; unpinned = Some ctx }
        >>= fun () -> f ()
      in
      inner_fut_ref := Some inner;
      ignore (Future.run_with_state inner worker_state);
      post_callback ();
      (* Drain anything that was pushed during the initial advance, then
         release the [draining] gate. *)
      Op_queue.drain_mailbox ctx
    in
    (* Best-effort hand-off to a worker.  If every worker is busy we run
       the body on the loop domain — the task remains correct (its
       Abb_fut state is still serialized via [ctx.draining]); it just
       doesn't get parallelism this time around. *)
    if not (Abb_domain_pool.try_enqueue el.El.thread_pool body) then body ();
    (* Caller-abort hook for the task future.  [abort_inner] aborts the
       worker's [inner] chain on the worker's own [worker_state]; it is
       injected into the task's mailbox so it is drained behind the
       [ctx.draining] gate — only one domain ever drives [worker_state],
       satisfying [run_with_state]'s single-domain-owner invariant. *)
    let abort_inner () =
      match (!inner_fut_ref, !worker_state_ref) with
      | Some inner, Some ws -> ignore (Future.run_with_state (Future.abort inner) ws)
      | _, _ ->
          (* Unreachable: [body] publishes both refs while holding
             [draining], so any drainer running [abort_inner] sees them. *)
          ()
    in
    (* Runs when the caller aborts the task future.  Enqueue [abort_inner]
       and make sure a drainer picks it up — same push + CAS + dispatch
       [Op_queue.run_callback] uses.  Returns immediately: the worker
       unwinds at its next async suspension point, matching [abort_of]. *)
    let abort_hook () =
      Saturn.Single_consumer_queue.push ctx.Task_ctx.mailbox abort_inner;
      if Atomic.compare_and_set ctx.Task_ctx.draining false true then
        if
          not (Abb_domain_pool.try_enqueue el.El.thread_pool (fun () -> Op_queue.drain_mailbox ctx))
        then Op_queue.drain_mailbox ctx;
      Future.return ()
    in
    (* The task future the caller awaits.  Aborting it fires [abort_hook]
       and nothing else — the [Chan.recv] below is not in its dep graph. *)
    let result_p = Future.Promise.create ~abort:abort_hook () in
    (* Free-standing deliverer: dequeues the worker's single wire and
       resolves [result_p].  It is never a dependency of [task], so
       aborting [task] never aborts this [Chan.recv] (which would orphan
       the worker's later [Chan.send] and deadlock).  [set]/[set_exn]/
       [abort] on an already-aborted promise are no-ops, so a wire that
       races in after the caller aborted is silently dropped.

       [Chan.recv result_ch] is driven on [outer_s] (the caller's run state), so its resume routes by
       [unpinned_of_state outer_s] -- the caller's own gate (or inline on the loop for a pinned/root
       caller).  No [set_data] is needed to steer the routing: it follows the run state. *)
    let deliver_result =
      let open Future.Infix_monad in
      Chan.recv result_ch
      >>= fun wire ->
      Future.with_state (fun s ->
          let drive =
            match wire with
            | Ok (Tw_det v) -> Future.Promise.set result_p v
            | Ok (Tw_exn (e, bt)) -> Future.Promise.set_exn result_p (e, bt)
            | Ok Tw_aborted -> Future.abort (Future.Promise.future result_p)
            | Error `Chan_closed ->
                (* The result_ch is private to this Task; nothing closes
                   it.  If we ever reach here, the worker died without
                   delivering. *)
                assert false
          in
          ignore (Future.run_with_state drive s);
          (s, Future.return ()))
    in
    ignore (Future.run_with_state deliver_result outer_s);
    let task =
      let open Future.Infix_monad in
      Future.fork (Future.set_data outer_data >>= fun () -> Future.Promise.future result_p)
    in
    (outer_s, task)

  (* Run a Task with [~pinned:true] when the *caller* is unpinned (its
     chain runs on a worker domain).  [run_pinned]'s fast path forks the
     child inline into the caller's [State.t]; doing that for an unpinned
     caller would drive the child — and every async op it issues with
     [unpinned_ctx = None], whose callbacks run inline on the loop domain
     — across two domains on one [Abb_fut.State.t].

     Structurally this mirrors [run_unpinned] (see it for the
     rendezvous-channel rationale and the [task] / [result_p] split).
     The differences are all domain-specific:
       - the body runs on the loop domain ([Chan.on_scheduler], an
         [Op.Run] with [unpinned_ctx = None]) rather than on a worker;
       - the child's chain data carries [unpinned = None] — it is
         genuinely pinned;
       - the inner chain gets its own fresh [sched_state], driven only
         by the loop domain (the body, the child's own [unpinned = None]
         op callbacks, and the abort all run there);
       - the inner chain's terminal state is observed by a single
         [await_bind] watcher — it fires exactly once, so the [delivered]
         CAS [run_unpinned] needs is unnecessary here;
       - abort is routed to the inner chain via [Chan.on_scheduler], not
         through a [Task_ctx] mailbox. *)
  let run_pinned_off_loop (type a) ?name (f : unit -> a Future.t) ~outer_data s =
    let outer_s = s in
    let el = el_of s in
    let new_id = Atomic.fetch_and_add el.El.task_counter 1 in
    (* Cross-domain rendezvous channel: the loop-domain body sends the
       inner chain's one terminal state, the caller-side [deliver_result]
       receives it. *)
    let result_ch : a task_wire Chan.t = Chan.create ~capacity:1 () in
    (* [inner] / [sched_state] are created inside [body], which runs on
       the loop domain.  [body] and [abort_inner] are both [Op.Run] ops
       on the loop domain's single-consumer queue; [body] is submitted
       before [task] is handed back, and the caller can only abort once
       it holds [task], so [abort_inner] is always enqueued strictly
       after [body] — the refs are published by the time it runs. *)
    let inner_ref = ref None in
    let sched_state_ref = ref None in
    let body () =
      let sched_state = Abb_fut.State.create { El.el; owning = None } in
      sched_state_ref := Some sched_state;
      let inner =
        let open Future.Infix_monad in
        Future.set_data { El.task_id = new_id; task_name = name; unpinned = None }
        >>= fun () -> f ()
      in
      inner_ref := Some inner;
      (* Observe [inner]'s terminal state and ship it over [result_ch].
         Driven on [sched_state] (loop domain); [await_bind] fires its
         callback exactly once, when [inner] settles.  This watcher is
         never a dependency of [task], so aborting [task] cannot abort
         it and orphan the [Chan.send]. *)
      let watcher =
        Future.await_bind
          (fun set ->
            Chan.send
              result_ch
              (match set with
              | `Det v -> Tw_det v
              | `Aborted -> Tw_aborted
              | `Exn (e, bt) -> Tw_exn (e, bt)))
          inner
      in
      ignore (Future.run_with_state watcher sched_state)
    in
    Chan.on_scheduler el body;
    (* Abort [inner] on its own [sched_state] — always from the loop
       domain, so [sched_state] keeps a single owner. *)
    let abort_inner () =
      match (!inner_ref, !sched_state_ref) with
      | Some inner, Some sched_state ->
          ignore (Future.run_with_state (Future.abort inner) sched_state)
      | _, _ ->
          (* Unreachable: the [body] op is dispatched before this abort
             op, so both refs are published.  Mirrors [run_unpinned]. *)
          ()
    in
    (* Runs when the caller aborts the task future.  Route the abort onto
       the loop domain and return immediately; the body unwinds at its
       next async suspension point. *)
    let abort_hook () =
      Chan.on_scheduler el abort_inner;
      Future.return ()
    in
    let result_p = Future.Promise.create ~abort:abort_hook () in
    (* Free-standing deliverer (identical in shape to [run_unpinned]'s):
       dequeues the one wire and resolves [result_p].  Never a dependency
       of [task], so aborting [task] never aborts this [Chan.recv].

       [Chan.recv result_ch] is driven on [outer_s] (the caller's run state), so its resume routes by
       [unpinned_of_state outer_s] -- the caller's own gate -- with no [set_data] needed. *)
    let deliver_result =
      let open Future.Infix_monad in
      Chan.recv result_ch
      >>= fun wire ->
      Future.with_state (fun s ->
          let drive =
            match wire with
            | Ok (Tw_det v) -> Future.Promise.set result_p v
            | Ok (Tw_exn (e, bt)) -> Future.Promise.set_exn result_p (e, bt)
            | Ok Tw_aborted -> Future.abort (Future.Promise.future result_p)
            | Error `Chan_closed ->
                (* [result_ch] is private to this Task; nothing closes it. *)
                assert false
          in
          ignore (Future.run_with_state drive s);
          (s, Future.return ()))
    in
    ignore (Future.run_with_state deliver_result outer_s);
    let task =
      let open Future.Infix_monad in
      Future.fork (Future.set_data outer_data >>= fun () -> Future.Promise.future result_p)
    in
    (outer_s, task)

  let run_pinned ?name ~outer_data f s =
    (* [~pinned:true] guarantees the child's body and callbacks run on
       the loop domain.  How we achieve that depends on the *caller*:
       a pinned or root caller already runs on the loop domain, so
       forking the child inline into the caller's [State.t] is correct
       and free; an unpinned caller runs on a worker domain, so forking
       inline would place the child there and race two domains on one
       [State.t] — it must be routed onto the loop instead.

       [outer_data] is the caller's chain data, captured eagerly by
       [run] at the [Task.run] call site.  It must not be read here via
       [peek_chain_data]: this function runs inside [run]'s [with_state]
       closure, a deferred advance with no [with_chain_data] active, so
       a [peek_chain_data] here would see the enclosing scope and misread
       an unpinned caller as pinned (see the eager-capture rule used by
       [Sys.sleep] and friends). *)
    match outer_data.El.unpinned with
    | None ->
        let t = el_of s in
        let new_id = Atomic.fetch_and_add t.El.task_counter 1 in
        let inner_chain =
          let open Future.Infix_monad in
          Future.set_data { El.task_id = new_id; task_name = name; unpinned = None }
          >>= fun () -> f ()
        in
        (* Wrap the forked chain with an outer [set_data outer_data] so
           the awaiter, when binding on the task future, inherits the
           awaiter's chain data (not the inner task's data). *)
        let task =
          let open Future.Infix_monad in
          Future.fork (Future.set_data outer_data >>= fun () -> inner_chain)
        in
        (s, task)
    | Some _ -> run_pinned_off_loop ?name f ~outer_data s

  let run ?name ?(pinned = true) f =
    (* Capture the caller's chain data eagerly, at the [Task.run] call
       site, where the enclosing bind continuation still has the
       caller's [with_chain_data] installed.  Reading it inside the
       [with_state] closure below would be too late — that closure runs
       during a deferred advance with the DLS restored to the enclosing
       scope (the same eager-capture rule [Sys.sleep] follows for
       [unpinned_ctx]). *)
    let outer_data = Future.peek_chain_data () in
    Future.with_state (fun s ->
        if pinned then run_pinned ?name ~outer_data f s else run_unpinned ?name ~outer_data f s)
end

module Sys = struct
  let sleep duration =
    assert (duration >= 0.0);
    Future.with_state (fun s ->
        let el = el_of s in
        let state = { Op.aborted = Atomic.make false; handle = Handle.None } in
        let p = Future.Promise.create ~abort:(abort_of el state) () in
        let ms = max 1 (int_of_float (duration *. 1000.0)) in
        Op_queue.submit
          el
          {
            Op.state;
            body =
              Op.Sleep
                {
                  ms;
                  on_fire = (fun () -> ignore (Future.run_with_state (Future.Promise.set p ()) s));
                };
            unpinned_ctx = unpinned_of_state s;
          };
        (s, Future.Promise.future p))

  let time () =
    Future.with_state (fun s ->
        let el = el_of s in
        (s, Future.return el.El.curr_time))

  let monotonic () =
    Future.with_state (fun s ->
        let el = el_of s in
        (s, Future.return Mtime.Span.(to_float_ns el.El.mono_time /. sec_ns)))
end

module Thread = struct
  let run f =
    Future.with_state (fun s ->
        let el = el_of s in
        (* Share the op's [aborted] atomic with the promise's abort
           callback so a [Future.abort] both (a) lets the pool worker
           skip the thunk if it's still queued and (b) tells [on_done]
           to suppress the result if the worker already ran it. *)
        let op_state = { Op.aborted = Atomic.make false; handle = Handle.None } in
        let p =
          Future.Promise.create
            ~abort:(fun () ->
              Atomic.set op_state.Op.aborted true;
              Future.return ())
            ()
        in
        let on_done result =
          let fut =
            if Atomic.get op_state.Op.aborted then Future.return ()
            else
              match result with
              | Ok v -> Future.Promise.set p v
              | Error exn -> Future.Promise.set_exn p exn
          in
          ignore (Future.run_with_state fut s)
        in
        Op_queue.submit
          el
          {
            Op.state = op_state;
            body = Op.Thread { f; on_done };
            unpinned_ctx = unpinned_of_state s;
          };
        (s, Future.Promise.future p))
end

let safe_call f = try Ok (f ()) with e -> Error (`Unexpected e)

(* The filesystem calls are implemented through a thread call because there is
   no guarantee that they will not block, for example on an NFS system. *)
module File = struct
  type t = Unix.file_descr

  let to_native t = t
  let of_native t = t
  let stdin = Unix.stdin
  let stdout = Unix.stdout
  let stderr = Unix.stderr

  let mode_of_flags flags =
    List.map
      ~f:
        Abb_intf.File.Flag.(
          function
          | Read_only -> Unix.O_RDONLY
          | Write_only -> Unix.O_WRONLY
          | Create _ -> Unix.O_CREAT
          | Read_write -> Unix.O_RDWR
          | Append -> Unix.O_APPEND
          | Truncate -> Unix.O_TRUNC
          | Exclusive -> Unix.O_EXCL)
      flags

  let perm_of_flags flags =
    let creates =
      List.filter
        ~f:
          Abb_intf.File.Flag.(
            function
            | Create _ -> true
            | _ -> false)
        flags
    in
    match creates with
    | [ Abb_intf.File.Flag.Create perm ] -> perm
    | _ -> 0

  let open_file ~flags path =
    try
      let t =
        Unix.openfile
          path
          ~mode:(Unix.O_CLOEXEC :: Unix.O_NONBLOCK :: mode_of_flags flags)
          ~perm:(perm_of_flags flags)
      in
      Future.return (Ok t)
    with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Future.return
          (Error
             (match err with
             | ENOTDIR -> `E_not_dir
             | ENAMETOOLONG -> `E_name_too_long
             | ENOENT -> `E_no_entity
             | EACCES -> `E_access
             | EROFS | EPERM -> `E_permission
             | ELOOP -> `E_loop
             | ENFILE | EMFILE -> `E_file_table_full
             | ENOSPC -> `E_no_space
             | EIO -> `E_io
             | EEXIST -> `E_exists
             | EINVAL -> `E_invalid
             | _ -> `Unexpected exn))
    | exn -> Future.return (Error (`Unexpected exn))

  let read_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EIO -> `E_io
          | EINVAL -> `E_invalid
          | EISDIR -> `E_is_dir
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let read t ~buf ~pos ~len =
    try Future.return (Ok (Unix.read t ~buf ~pos ~len)) with
    | Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
        Future.with_state (fun s ->
            with_poll s ~fd:t ~events:[ `READABLE ] ~retry:(fun () ->
                try Ok (Unix.read t ~buf ~pos ~len) with exn -> read_err exn))
    | exn -> Future.return (read_err exn)

  let pread t ~offset ~buf ~pos ~len =
    try
      let n = Unix.lseek t offset ~mode:Unix.SEEK_SET in
      assert (n = offset);
      read t ~buf ~pos ~len
    with
    | Unix.Unix_error (Unix.ENXIO, _, _) -> Future.return (Error `E_nxio)
    | exn -> Future.return (Error (`Unexpected exn))

  let write_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EPIPE -> `E_pipe
          | EINVAL -> `E_invalid
          | ENOSPC -> `E_no_space
          | EIO -> `E_io
          | EROFS -> `E_permission
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let write' ~buf ~pos ~len t =
    try Future.return (Ok (Unix.write t ~buf ~pos ~len)) with
    | Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
        Future.with_state (fun s ->
            with_poll s ~fd:t ~events:[ `WRITABLE ] ~retry:(fun () ->
                try Ok (Unix.write t ~buf ~pos ~len) with exn -> write_err exn))
    | exn -> Future.return (write_err exn)

  let rec write_buf t buf =
    let open Future.Infix_monad in
    write'
      t
      ~buf:buf.Abb_intf.Write_buf.buf
      ~pos:buf.Abb_intf.Write_buf.pos
      ~len:buf.Abb_intf.Write_buf.len
    >>= function
    | Ok n when n < buf.Abb_intf.Write_buf.len -> (
        let buf = Abb_intf.Write_buf.{ buf with pos = buf.pos + n; len = buf.len - n } in
        write_buf t buf
        >>= function
        | Ok n' -> Future.return (Ok (n + n'))
        | Error _ as err -> Future.return err)
    | Ok n -> Future.return (Ok n)
    | Error _ as err -> Future.return err

  let write_bufs t bufs =
    let rec write_bufs' t = function
      | [] -> Future.return (Ok 0)
      | b :: bs -> (
          let open Future.Infix_monad in
          write_buf t b
          >>= function
          | Ok n -> (
              write_bufs' t bs
              >>= function
              | Ok n' -> Future.return (Ok (n + n'))
              | Error _ as err -> Future.return err)
          | Error _ as err -> Future.return err)
    in
    write_bufs' t bufs

  let write t bufs = write_bufs t bufs

  let pwrite t ~offset bufs =
    try
      let n = Unix.lseek t offset ~mode:Unix.SEEK_SET in
      assert (n = offset);
      write_bufs t bufs
    with
    | Unix.Unix_error (Unix.ENXIO, _, _) -> Future.return (Error `E_nxio)
    | exn -> Future.return (Error (`Unexpected exn))

  let lseek' t ~offset = function
    | Abb_intf.File.Seek.Cur ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_CUR);
        Ok ()
    | Abb_intf.File.Seek.Set ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_SET);
        Ok ()
    | Abb_intf.File.Seek.End ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_END);
        Ok ()

  let lseek t ~offset seek =
    try lseek' t ~offset seek with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | ENXIO -> `E_nxio
          | EINVAL -> `E_invalid
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let close t =
    Future.with_state (fun s ->
        let el = el_of s in
        let state = { Op.aborted = Atomic.make false; handle = Handle.None } in
        Op_queue.submit el { Op.state; body = Op.Close_fd t; unpinned_ctx = unpinned_of_state s };
        (s, Future.return (Ok ())))

  let unlink path =
    try Future.return (Ok (Unix.unlink path)) with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Future.return
          (Error
             (match err with
             | ENOTDIR -> `E_not_dir
             | EISDIR -> `E_is_dir
             | ENAMETOOLONG -> `E_name_too_long
             | ENOENT -> `E_no_entity
             | EACCES -> `E_access
             | ELOOP -> `E_loop
             | EPERM -> `E_permission
             | EIO -> `E_io
             | ENOSPC -> `E_no_space
             | _ -> `Unexpected exn))
    | exn -> Future.return (Error (`Unexpected exn))

  let mkdir path perm =
    Thread.run (fun () ->
        try Ok (Unix.mkdir ~perm path) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | EISDIR -> `E_is_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | EEXIST -> `E_exists
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let rmdir path =
    Thread.run (fun () ->
        try Ok (Unix.rmdir path) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTEMPTY -> `E_not_empty
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EPERM -> `E_permission
              | EINVAL -> `E_invalid
              | EBUSY -> `E_busy
              | EIO -> `E_io
              | EEXIST -> `E_exists
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let readdir path =
    Thread.run (fun () -> safe_call (fun () -> Array.to_list (Sys_stdlib.readdir path)))

  let of_unix_stat stat =
    let of_file_kind = function
      | Unix.S_REG -> Abb_intf.File.File_kind.Regular
      | Unix.S_DIR -> Abb_intf.File.File_kind.Directory
      | Unix.S_CHR -> Abb_intf.File.File_kind.Char
      | Unix.S_BLK -> Abb_intf.File.File_kind.Block
      | Unix.S_LNK -> Abb_intf.File.File_kind.Symlink
      | Unix.S_FIFO -> Abb_intf.File.File_kind.Fifo
      | Unix.S_SOCK -> Abb_intf.File.File_kind.Socket
    in
    Abb_intf.File.Stat.
      {
        dev = stat.Unix.st_dev;
        inode = stat.Unix.st_ino;
        kind = of_file_kind stat.Unix.st_kind;
        perm = stat.Unix.st_perm;
        num_links = stat.Unix.st_nlink;
        uid = stat.Unix.st_uid;
        gid = stat.Unix.st_gid;
        rdev = stat.Unix.st_rdev;
        size = stat.Unix.st_size;
        atime = stat.Unix.st_atime;
        mtime = stat.Unix.st_mtime;
        ctime = stat.Unix.st_ctime;
      }

  let stat path =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.stat path)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fstat t =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.fstat t)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EINVAL -> `E_invalid
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let lstat path =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.lstat path)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let rename ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.rename ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | EPERM | EROFS -> `E_permission
              | ELOOP -> `E_loop
              | ENOTDIR -> `E_not_dir
              | EISDIR -> `E_is_dir
              | ENOSPC -> `E_no_space
              | EIO -> `E_io
              | EINVAL -> `E_invalid
              | ENOTEMPTY -> `E_not_empty
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let truncate path len =
    Thread.run (fun () ->
        try Ok (Unix.truncate path ~len:(Int64.to_int len)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EISDIR -> `E_is_dir
              | EINVAL -> `E_invalid
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let ftruncate t len =
    Thread.run (fun () ->
        try Ok (Unix.ftruncate t ~len:(Int64.to_int len)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EISDIR -> `E_is_dir
              | EINVAL -> `E_invalid
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let chmod path mode =
    Thread.run (fun () ->
        try Ok (Unix.chmod path ~perm:mode) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fchmod t mode =
    Thread.run (fun () ->
        try Ok (Unix.fchmod t ~perm:mode) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EINVAL -> `E_invalid
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let symlink ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.symlink ~to_dir:false ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EEXIST -> `E_exists
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let link ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.link ~follow:true ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EOPNOTSUPP -> `E_op_not_supported
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EEXIST -> `E_exists
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let chown path ~uid ~gid =
    Thread.run (fun () ->
        try Ok (Unix.chown path ~uid ~gid) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fchown t ~uid ~gid =
    Thread.run (fun () ->
        try Ok (Unix.fchown t ~uid ~gid) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))
end

module Socket = struct
  type tcp
  type udp
  type _ t = Abb_fd_socket.t

  (* Fail fast once the handle is closed; otherwise run [f] with the live fd.
     [`E_file_closed] is in every guarded op's error type ([Abb_intf.Errors]).
     Covers connect/close and the plaintext data path; TLS reads/writes go
     through Otls on the raw fd and are not covered here.  [getsockname]/
     [getpeername] (no result type) and [readable]/[writable] (non-result
     future) skip the guard -- Unix raises EBADF for a truly bad fd, and neither
     is used on the hot path. *)
  let guarded t f =
    if Abb_fd_socket.is_closed t then Error `E_file_closed else f (Abb_fd_socket.fd t)

  let guarded_fut t f =
    if Abb_fd_socket.is_closed t then Future.return (Error `E_file_closed)
    else f (Abb_fd_socket.fd t)

  (* Guard-then-poll: fail fast if [t] is closed, otherwise wait for [t] to be
     [events]-ready and resolve with [retry fd].  Flattens the
     guard/with_state/with_poll nesting shared by the single-shot read ops. *)
  let with_open_poll t ~events ~retry =
    guarded_fut t (fun fd ->
        Future.with_state (fun s -> with_poll s ~fd ~events ~retry:(fun () -> retry fd)))

  (* Partial-write loop for [send]/[sendto]: re-arm a WRITABLE poll for each
     remaining chunk, calling [write_chunk] (one [send]/[sendto] syscall) until
     all of [bufs] is written, mapping a syscall exn through [err_of].  One
     op-state is reused across the chain so an abort tears down the live poll. *)
  let write_via_poll fd ~bufs ~write_chunk ~err_of =
    let state = { Op.aborted = Atomic.make false; handle = Handle.None } in
    Future.with_state (fun s ->
        let el = el_of s in
        let p = Future.Promise.create ~abort:(abort_of el state) () in
        let rec send' ~total ~pos = function
          | [] -> ignore (Future.run_with_state (Future.Promise.set p (Ok total)) s)
          | wb :: bufs as all_bufs ->
              let on_event _result =
                try
                  let len = wb.Abb_intf.Write_buf.len - pos in
                  let n = write_chunk fd ~buf:wb.Abb_intf.Write_buf.buf ~pos ~len in
                  let total = total + n in
                  if n = len then send' ~total ~pos:0 bufs else send' ~total ~pos:(pos + n) all_bufs
                with exn -> ignore (Future.run_with_state (Future.Promise.set p (err_of exn)) s)
              in
              Op_queue.submit
                el
                {
                  Op.state;
                  body = Op.Poll { fd; events = [ `WRITABLE ]; on_event };
                  unpinned_ctx = unpinned_of_state s;
                }
        in
        send' ~total:0 ~pos:0 bufs;
        (s, Future.Promise.future p))

  let unix_of_domain = function
    | Abb_intf.Socket.Domain.Unix -> Unix.PF_UNIX
    | Abb_intf.Socket.Domain.Inet4 -> Unix.PF_INET
    | Abb_intf.Socket.Domain.Inet6 -> Unix.PF_INET6

  let domain_of_unix = function
    | Unix.PF_UNIX -> Abb_intf.Socket.Domain.Unix
    | Unix.PF_INET -> Abb_intf.Socket.Domain.Inet4
    | Unix.PF_INET6 -> Abb_intf.Socket.Domain.Inet6

  let socket_type_of_unix = function
    | Unix.SOCK_STREAM -> Abb_intf.Socket.Socket_type.Stream
    | Unix.SOCK_DGRAM -> Abb_intf.Socket.Socket_type.Dgram
    | Unix.SOCK_RAW -> Abb_intf.Socket.Socket_type.Raw
    | Unix.SOCK_SEQPACKET -> Abb_intf.Socket.Socket_type.Seqpacket

  let unix_of_socket_type = function
    | Abb_intf.Socket.Socket_type.Stream -> Unix.SOCK_STREAM
    | Abb_intf.Socket.Socket_type.Dgram -> Unix.SOCK_DGRAM
    | Abb_intf.Socket.Socket_type.Raw -> Unix.SOCK_RAW
    | Abb_intf.Socket.Socket_type.Seqpacket -> Unix.SOCK_SEQPACKET

  let addrinfo_of_unix_addrinfo ai =
    let family = domain_of_unix ai.Unix.ai_family in
    let sock_type = socket_type_of_unix ai.Unix.ai_socktype in
    let addr =
      match ai.Unix.ai_addr with
      | Unix.ADDR_UNIX s -> Abb_intf.Socket.Sockaddr.Unix s
      | Unix.ADDR_INET (a, p) -> Abb_intf.Socket.Sockaddr.(Inet { addr = a; port = p })
    in
    Abb_intf.Socket.Addrinfo.
      { family; sock_type; protocol = ai.Unix.ai_protocol; addr; canon_name = ai.Unix.ai_canonname }

  let unix_sockaddr_of_sockaddr = function
    | Abb_intf.Socket.Sockaddr.Unix s -> Unix.ADDR_UNIX s
    | Abb_intf.Socket.Sockaddr.Inet inet ->
        Abb_intf.Socket.Sockaddr.(Unix.ADDR_INET (inet.addr, inet.port))

  let sockaddr_of_unix_sockaddr = function
    | Unix.ADDR_UNIX s -> Abb_intf.Socket.Sockaddr.Unix s
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let getaddrinfo_options_of_hints hints =
    List.map
      ~f:
        Abb_intf.Socket.Addrinfo_hints.(
          function
          | Family domain -> Unix.AI_FAMILY (unix_of_domain domain)
          | Socket_type socktype -> Unix.AI_SOCKTYPE (unix_of_socket_type socktype)
          | Protocol p -> Unix.AI_PROTOCOL p
          | Numeric_host -> Unix.AI_NUMERICHOST
          | Canon_name -> Unix.AI_CANONNAME
          | Passive -> Unix.AI_PASSIVE)
      hints

  let getaddrinfo ?hints query =
    Thread.run (fun () ->
        safe_call (fun () ->
            let hints =
              match hints with
              | Some h -> h
              | None -> []
            in
            let ai =
              match query with
              | Abb_intf.Socket.Addrinfo_query.Host h ->
                  Unix.getaddrinfo h "" (getaddrinfo_options_of_hints hints)
              | Abb_intf.Socket.Addrinfo_query.Service s ->
                  Unix.getaddrinfo "" s (getaddrinfo_options_of_hints hints)
              | Abb_intf.Socket.Addrinfo_query.Host_service (h, s) ->
                  Unix.getaddrinfo h s (getaddrinfo_options_of_hints hints)
            in
            List.map ~f:addrinfo_of_unix_addrinfo ai))

  let getsockname t =
    match Unix.getsockname (Abb_fd_socket.fd t) with
    | Unix.ADDR_UNIX str -> Abb_intf.Socket.Sockaddr.Unix str
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let getpeername t =
    match Unix.getpeername (Abb_fd_socket.fd t) with
    | Unix.ADDR_UNIX str -> Abb_intf.Socket.Sockaddr.Unix str
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let recvfrom_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | ECONNRESET -> `E_connection_reset
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let recvfrom t ~buf ~pos ~len =
    with_open_poll t ~events:[ `READABLE ] ~retry:(fun fd ->
        try
          let n, addr = Unix.recvfrom fd ~buf ~pos ~len ~mode:[] in
          Ok (n, sockaddr_of_unix_sockaddr addr)
        with exn -> recvfrom_err exn)

  let sendto_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EACCES -> `E_access
          | ENOBUFS -> `E_no_buffers
          | EHOSTUNREACH -> `E_host_unreachable
          | EHOSTDOWN -> `E_host_down
          | ECONNREFUSED -> `E_connection_refused
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let sendto t ~bufs sockaddr =
    let addr = unix_sockaddr_of_sockaddr sockaddr in
    guarded_fut t (fun fd ->
        write_via_poll fd ~bufs ~err_of:sendto_err ~write_chunk:(fun fd ~buf ~pos ~len ->
            Unix.sendto fd ~buf ~pos ~len ~mode:[] ~addr))

  let close t =
    Future.with_state (fun s ->
        (* Idempotent: only the first close submits the deferred [Unix.close], so
           a reused fd number is never double-closed. *)
        (if Abb_fd_socket.close_once t then
           let el = el_of s in
           let state = { Op.aborted = Atomic.make false; handle = Handle.None } in
           Op_queue.submit
             el
             {
               Op.state;
               body = Op.Close_fd (Abb_fd_socket.fd t);
               unpinned_ctx = unpinned_of_state s;
             });
        (s, Future.return (Ok ())))

  let listen t ~backlog =
    guarded t (fun fd ->
        try
          Unix.listen fd ~max:backlog;
          Ok ()
        with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EDESTADDRREQ -> `E_dest_address_required
              | EINVAL -> `E_invalid
              | EOPNOTSUPP -> `E_op_not_supported
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let accept_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EMFILE | ENFILE -> `E_file_table_full
          | EINVAL -> `E_invalid
          | ECONNABORTED -> `E_connection_aborted
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let accept_eagain_err = function
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | ENOTSOCK | EBADF -> `E_bad_file
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let accept t =
    guarded_fut t (fun fd ->
        try
          let nfd, _ = Unix.accept ~cloexec:true fd in
          Unix.set_nonblock nfd;
          Future.return (Ok (Abb_fd_socket.make nfd))
        with
        | Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
            Future.with_state (fun s ->
                with_poll s ~fd ~events:[ `READABLE ] ~retry:(fun () ->
                    try
                      let nfd, _ = Unix.accept ~cloexec:true fd in
                      Unix.set_nonblock nfd;
                      Ok (Abb_fd_socket.make nfd)
                    with exn -> accept_err exn))
        | exn -> Future.return (accept_eagain_err exn))

  let create_sock ~kind ~domain =
    try
      let fd = Unix.socket ~cloexec:true ~domain:(unix_of_domain domain) ~kind ~protocol:0 in
      Unix.set_nonblock fd;
      Ok (Abb_fd_socket.make fd)
    with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EACCES -> `E_access
          | EAFNOSUPPORT -> `E_address_family_not_supported
          | EMFILE | ENFILE -> `E_file_table_full
          | ENOBUFS -> `E_no_buffers
          | EPERM -> `E_permission
          | EPROTONOSUPPORT -> `E_protocol_not_supported
          | EPROTOTYPE -> `E_protocol_type
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let readable t =
    Future.with_state (fun s ->
        with_poll s ~fd:(Abb_fd_socket.fd t) ~events:[ `READABLE ] ~retry:(fun () -> ()))

  let writable t =
    Future.with_state (fun s ->
        with_poll s ~fd:(Abb_fd_socket.fd t) ~events:[ `WRITABLE ] ~retry:(fun () -> ()))

  module Tcp = struct
    let to_native t = Abb_fd_socket.fd t
    let of_native t = Abb_fd_socket.make t
    let create = create_sock ~kind:Unix.SOCK_STREAM

    let bind t addr =
      guarded t (fun fd ->
          try
            Unix.setsockopt fd Unix.SO_REUSEADDR true;
            let sa = unix_sockaddr_of_sockaddr addr in
            Unix.bind fd ~addr:sa;
            Ok ()
          with
          | Unix.Unix_error (err, _, _) as exn ->
              let open Unix in
              Error
                (match err with
                | ENOTSOCK | EBADF -> `E_bad_file
                | EAGAIN -> `E_again
                | EINVAL -> `E_invalid
                | EADDRNOTAVAIL -> `E_address_not_available
                | EADDRINUSE -> `E_address_in_use
                | EAFNOSUPPORT -> `E_address_family_not_supported
                | EACCES -> `E_access
                | ENOTDIR -> `E_not_dir
                | EROFS | EPERM -> `E_permission
                | ENAMETOOLONG -> `E_name_too_long
                | ENOENT -> `E_no_entity
                | ELOOP -> `E_loop
                | EIO -> `E_io
                | EISDIR -> `E_is_dir
                | _ -> `Unexpected exn)
          | exn -> Error (`Unexpected exn))

    let connect_err = function
      | Unix.Unix_error (err, _, _) as exn ->
          let open Unix in
          Error
            (match err with
            | EBADF -> `E_bad_file
            | EINVAL -> `E_invalid
            | EADDRNOTAVAIL -> `E_address_not_available
            | EAFNOSUPPORT -> `E_address_family_not_supported
            | EISCONN -> `E_is_connected
            | ECONNREFUSED -> `E_connection_refused
            | ECONNRESET -> `E_connection_reset
            | ENETUNREACH -> `E_network_unreachable
            | EHOSTUNREACH -> `E_host_unreachable
            | EADDRINUSE -> `E_address_in_use
            | EACCES -> `E_access
            | _ -> `Unexpected exn)
      | exn -> Error (`Unexpected exn)

    let connect t addr =
      let sa = unix_sockaddr_of_sockaddr addr in
      guarded_fut t (fun fd ->
          try
            Unix.connect fd ~addr:sa;
            Future.return (Ok ())
          with
          | Unix.Unix_error (Unix.EINPROGRESS, _, _) ->
              Future.with_state (fun s ->
                  with_poll s ~fd ~events:[ `WRITABLE ] ~retry:(fun () -> Ok ()))
          | exn -> Future.return (connect_err exn))

    let recv_err = function
      | Unix.Unix_error (err, _, _) as exn ->
          let open Unix in
          Error
            (match err with
            | ENOTSOCK | EBADF -> `E_bad_file
            | ECONNRESET -> `E_connection_reset
            | ENOTCONN -> `E_not_connected
            | _ -> `Unexpected exn)
      | exn -> Error (`Unexpected exn)

    let recv t ~buf ~pos ~len =
      with_open_poll t ~events:[ `READABLE ] ~retry:(fun fd ->
          try Ok (Unix.recv fd ~buf ~pos ~len ~mode:[]) with exn -> recv_err exn)

    let send_err = function
      | Unix.Unix_error (err, _, _) as exn ->
          let open Unix in
          Error
            (match err with
            | ENOTSOCK | EBADF -> `E_bad_file
            | EACCES -> `E_access
            | ENOBUFS -> `E_no_buffers
            | EHOSTUNREACH -> `E_host_unreachable
            | EHOSTDOWN -> `E_host_down
            | EPIPE -> `E_pipe
            | _ -> `Unexpected exn)
      | exn -> Error (`Unexpected exn)

    let send t ~bufs =
      guarded_fut t (fun fd ->
          write_via_poll fd ~bufs ~err_of:send_err ~write_chunk:(fun fd ~buf ~pos ~len ->
              Unix.send fd ~buf ~pos ~len ~mode:[]))

    let nodelay t enabled =
      guarded t (fun fd ->
          try
            Unix.setsockopt fd Unix.TCP_NODELAY enabled;
            Ok ()
          with
          | Unix.Unix_error (err, _, _) as exn ->
              let open Unix in
              Error
                (match err with
                | ENOTSOCK | EBADF -> `E_bad_file
                | _ -> `Unexpected exn)
          | exn -> Error (`Unexpected exn))
  end

  module Udp = struct
    let to_native t = Abb_fd_socket.fd t
    let of_native t = Abb_fd_socket.make t
    let create = create_sock ~kind:Unix.SOCK_DGRAM
    let bind = Tcp.bind
  end
end

module Process = struct
  module Pid = struct
    type t = int
    type native = int

    let of_native n = n
    let to_native t = t
  end

  type t = {
    pid : Pid.t;
    exit_code : Abb_intf.Process.Exit_code.t Future.t;
  }

  let int_of_signal = function
    | Abb_intf.Process.Signal.SIGABRT -> Sys_stdlib.sigabrt
    | Abb_intf.Process.Signal.SIGFPE -> Sys_stdlib.sigfpe
    | Abb_intf.Process.Signal.SIGHUP -> Sys_stdlib.sighup
    | Abb_intf.Process.Signal.SIGILL -> Sys_stdlib.sigill
    | Abb_intf.Process.Signal.SIGINT -> Sys_stdlib.sigint
    | Abb_intf.Process.Signal.SIGKILL -> Sys_stdlib.sigkill
    | Abb_intf.Process.Signal.SIGSEGV -> Sys_stdlib.sigsegv
    | Abb_intf.Process.Signal.SIGTERM -> Sys_stdlib.sigterm
    | Abb_intf.Process.Signal.Num s -> s

  let signal_of_int n =
    if n = Sys_stdlib.sigabrt then Abb_intf.Process.Signal.SIGABRT
    else if n = Sys_stdlib.sigfpe then Abb_intf.Process.Signal.SIGFPE
    else if n = Sys_stdlib.sighup then Abb_intf.Process.Signal.SIGHUP
    else if n = Sys_stdlib.sigill then Abb_intf.Process.Signal.SIGILL
    else if n = Sys_stdlib.sigint then Abb_intf.Process.Signal.SIGINT
    else if n = Sys_stdlib.sigkill then Abb_intf.Process.Signal.SIGKILL
    else if n = Sys_stdlib.sigsegv then Abb_intf.Process.Signal.SIGSEGV
    else if n = Sys_stdlib.sigterm then Abb_intf.Process.Signal.SIGTERM
    else Abb_intf.Process.Signal.Num n

  let wait_on_pid pid =
    Thread.run (fun () ->
        let pid', signal = Unix.waitpid ~mode:[] pid in
        assert (pid = pid');
        match signal with
        | Unix.WEXITED code -> Abb_intf.Process.Exit_code.Exited code
        | Unix.WSIGNALED code -> Abb_intf.Process.Exit_code.Signaled (signal_of_int code)
        | Unix.WSTOPPED code -> Abb_intf.Process.Exit_code.Stopped (signal_of_int code))

  let spawn ~stdin ~stdout ~stderr init_args =
    try
      let pid =
        let module P = Abb_intf.Process in
        match init_args.P.env with
        | Some env ->
            let env =
              CCArray.of_list @@ CCList.map (fun (k, v) -> CCString.concat "=" [ k; v ]) env
            in
            Unix.create_process_env
              ~prog:init_args.P.exec_name
              ~args:(CCArray.of_list init_args.P.args)
              ~env
              ~stdin
              ~stdout
              ~stderr
        | None ->
            Unix.create_process
              ~prog:init_args.P.exec_name
              ~args:(CCArray.of_list init_args.P.args)
              ~stdin
              ~stdout
              ~stderr
      in
      Ok { pid; exit_code = wait_on_pid pid }
    with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EAGAIN -> `E_again
          | ENOMEM -> `E_no_memory
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let pid t = t.pid
  let wait t = t.exit_code

  let exit_code t =
    match Future.state t.exit_code with
    | `Det exit_code -> Some exit_code
    | `Undet | `Aborted | `Exn _ -> None

  let signal_pid ~pid signal = Unix.kill ~pid ~signal:(int_of_signal signal)
  let signal t signal = signal_pid ~pid:t.pid signal
end
