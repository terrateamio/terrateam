type enqueue_err = [ `Closed ] [@@deriving show]

module Queue : sig
  type 'a t

  val empty : 'a t
  val of_list : 'a list -> 'a t
  val to_list : 'a t -> 'a list
  val enqueue : 'a -> 'a t -> 'a t
end = struct
  type 'a t = {
    front : 'a list;
    rear : 'a list;
  }

  let empty = { front = []; rear = [] }
  let of_list front = { front; rear = [] }
  let to_list { front; rear } = front @ CCList.rev rear
  let enqueue v t = { t with rear = v :: t.rear }
end

module Make (S : Abb_intf.S) (Key : Map.OrderedType) = struct
  module Fut = S.Future
  module Fut_comb = Abb_future_combinators.Make (Fut)
  module Service = Abb_service_local.Make (S)
  module Key_set = CCSet.Make (Key)

  module Task = struct
    type 'a t = {
      keys : Key.t list;
      task : 'a;
    }
  end

  module Msg = struct
    type 'a t =
      | Enqueue of 'a Task.t
      | Drain of (unit, unit) Service.Request.t
      | Completed of { keys : Key.t list }
  end

  module Server = struct
    type 'a t = {
      slots : int;
      used_slots : int;
      f : 'a -> unit Fut.t;
      locked_keys : Key_set.t;
      queue : 'a Task.t Queue.t;
    }

    let make slots f =
      { slots; used_slots = 0; f; locked_keys = Key_set.empty; queue = Queue.empty }

    let exec task f chan =
      Fut_comb.ignore
        (Fut.fork
           (Fut_comb.with_finally
              (fun () -> Fut_comb.ignore (f task.Task.task))
              ~finally:(fun () ->
                Fut_comb.ignore (S.Chan.send chan (Msg.Completed { keys = task.Task.keys })))))

    let task_can_run would_lock_keys locked_keys keys =
      (not (CCList.exists (CCFun.flip Key_set.mem locked_keys) keys))
      && not (CCList.exists (CCFun.flip Key_set.mem would_lock_keys) keys)

    let rec exec_available_work' chan t would_lock_keys acc = function
      | [] -> Fut.return { t with queue = Queue.of_list (CCList.rev acc) }
      | tasks when t.slots <= t.used_slots ->
          Fut.return { t with queue = Queue.of_list (CCList.rev acc @ tasks) }
      | task :: tasks when task_can_run would_lock_keys t.locked_keys task.Task.keys ->
          let open Fut.Infix_monad in
          let locked_keys = Key_set.add_list t.locked_keys task.Task.keys in
          exec task t.f chan
          >>= fun () ->
          exec_available_work'
            chan
            { t with used_slots = t.used_slots + 1; locked_keys }
            would_lock_keys
            acc
            tasks
      | task :: tasks ->
          exec_available_work'
            chan
            t
            (Key_set.add_list would_lock_keys task.Task.keys)
            (task :: acc)
            tasks

    let exec_available_work chan t =
      exec_available_work' chan t Key_set.empty [] (Queue.to_list t.queue)

    (* Reply to a parked drain request by sending [`Det ()] over its
       reply chan.  This is the [respond] pattern with no user function
       to run -- we already have the value. *)
    let answer_drain req = Service.respond req (fun () -> Fut.return ())

    let rec loop_drain drains t chan =
      let open Fut.Infix_monad in
      S.Chan.recv chan
      >>= function
      | Ok (Msg.Drain drain) -> loop_drain (drain :: drains) t chan
      | Ok (Msg.Completed { keys }) -> (
          let locked_keys = CCList.fold_left (CCFun.flip Key_set.remove) t.locked_keys keys in
          let t = { t with used_slots = t.used_slots - 1; locked_keys } in
          exec_available_work chan t
          >>= function
          | { used_slots = 0; _ } -> Fut_comb.List.iter ~f:answer_drain drains
          | t -> loop_drain drains t chan)
      | Ok (Msg.Enqueue _) -> assert false
      | Error `Chan_closed -> assert false

    let rec loop t chan =
      let open Fut.Infix_monad in
      S.Chan.recv chan
      >>= function
      | Ok (Msg.Enqueue task) ->
          let t = { t with queue = Queue.enqueue task t.queue } in
          exec_available_work chan t >>= fun t -> loop t chan
      | Ok (Msg.Drain drain) when t.used_slots = 0 -> answer_drain drain
      | Ok (Msg.Drain drain) -> loop_drain [ drain ] t chan
      | Ok (Msg.Completed { keys }) ->
          let locked_keys = CCList.fold_left (CCFun.flip Key_set.remove) t.locked_keys keys in
          let t = { t with used_slots = t.used_slots - 1; locked_keys } in
          exec_available_work chan t >>= fun t -> loop t chan
      | Error `Chan_closed -> Fut.return ()
  end

  type 'a t = {
    (* [draining] is read by [enqueue] on the caller's domain and
       written by [drain_and_destroy] on potentially a different domain
       (under RFD-675 multi-domain, [enqueue] callers may run unpinned
       while [drain_and_destroy] runs on the scheduler).  An [Atomic.t]
       gives the cross-domain visibility a [mutable bool] does not:
       without it, an [enqueue] racing with a drain could read a stale
       [false], send [Msg.Enqueue] into the service Chan, and trip the
       [Msg.Enqueue -> assert false] invariant in [loop_drain].  The
       Atomic does NOT serialize the flip with the [Drain]-send below:
       that ordering is provided by setting the flag {i before} the
       [Service.call]. *)
    draining : bool Atomic.t;
    w : 'a Msg.t S.Chan.t;
  }

  let create ~slots f =
    let open Fut.Infix_monad in
    (* Service Chan carries only control traffic; the work queue lives
       inside [Server.t].  Pick a capacity that absorbs bursts without
       parking [enqueue] callers. *)
    Service.create ~capacity:100_000 (Server.loop (Server.make slots f))
    >>= fun w -> Fut.return { draining = Atomic.make false; w }

  let enqueue { draining; w } ~keys task =
    if Atomic.get draining then Fut.return (Error `Closed)
    else
      let open Fut.Infix_monad in
      S.Chan.send w (Msg.Enqueue Task.{ keys; task })
      >>= function
      | Ok () -> Fut.return (Ok ())
      | Error `Chan_closed -> Fut.return (Error `Closed)

  let destroy { w; _ } = S.Chan.close w

  let drain_and_destroy ({ w; _ } as t) =
    let open Fut.Infix_monad in
    (* Flip [draining] BEFORE issuing the [Drain] call.  This closes the
       window in which a concurrent [enqueue] could send [Msg.Enqueue]
       into the service Chan: any send racing with the drain would land
       in [loop_drain] and trip its [Msg.Enqueue -> assert false]
       invariant.  The post-flip [enqueue] short-circuits with
       [Error `Closed] without touching the Chan. *)
    Atomic.set t.draining true;
    Service.call w (fun req -> Msg.Drain req) ()
    >>= function
    | Ok () -> Fut.return ()
    | Error `Chan_closed -> Fut.return ()
end
