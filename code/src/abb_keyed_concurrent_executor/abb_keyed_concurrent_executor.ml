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

module Make (Fut : Abb_intf.Future.S) (Key : Map.OrderedType) = struct
  module Fut_comb = Abb_future_combinators.Make (Fut)
  module Channel = Abb_channel.Make (Fut)
  module Service = Abb_service_local.Make (Fut)
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
      | Drain of unit Fut.Promise.t
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

    let exec task f w =
      Fut_comb.ignore
        (Fut.fork
           (Fut_comb.with_finally
              (fun () -> Fut_comb.ignore (f task.Task.task))
              ~finally:(fun () ->
                Fut_comb.ignore (Channel.send w (Msg.Completed { keys = task.Task.keys })))))

    let task_can_run would_lock_keys locked_keys keys =
      (* Task can run if all none of its keys exist in the locked keys. *)
      (not (CCList.exists (CCFun.flip Key_set.mem locked_keys) keys))
      && not (CCList.exists (CCFun.flip Key_set.mem would_lock_keys) keys)

    let rec exec_available_work' w t would_lock_keys acc = function
      | [] -> Fut.return { t with queue = Queue.of_list (CCList.rev acc) }
      | tasks when t.slots <= t.used_slots ->
          Fut.return { t with queue = Queue.of_list (CCList.rev acc @ tasks) }
      | task :: tasks when task_can_run would_lock_keys t.locked_keys task.Task.keys ->
          let open Fut.Infix_monad in
          let locked_keys = Key_set.add_list t.locked_keys task.Task.keys in
          exec task t.f w
          >>= fun () ->
          exec_available_work'
            w
            { t with used_slots = t.used_slots + 1; locked_keys }
            would_lock_keys
            acc
            tasks
      | task :: tasks ->
          exec_available_work'
            w
            t
            (Key_set.add_list would_lock_keys task.Task.keys)
            (task :: acc)
            tasks

    let exec_available_work w t = exec_available_work' w t Key_set.empty [] (Queue.to_list t.queue)

    let rec loop_drain drains t w r =
      let open Fut.Infix_monad in
      Channel.recv r
      >>= function
      | `Ok (Msg.Drain drain) -> loop_drain (drain :: drains) t w r
      | `Ok (Msg.Completed { keys }) -> (
          let locked_keys = CCList.fold_left (CCFun.flip Key_set.remove) t.locked_keys keys in
          let t = { t with used_slots = t.used_slots - 1; locked_keys } in
          exec_available_work w t
          >>= function
          | { used_slots = 0; _ } -> Fut_comb.List.iter ~f:(CCFun.flip Fut.Promise.set ()) drains
          | t -> loop_drain drains t w r)
      | `Ok (Msg.Enqueue _) -> assert false
      | `Closed -> assert false

    let rec loop t w r =
      let open Fut.Infix_monad in
      Channel.recv r
      >>= function
      | `Ok (Msg.Enqueue task) ->
          let open Fut.Infix_monad in
          let t = { t with queue = Queue.enqueue task t.queue } in
          exec_available_work w t >>= fun t -> loop t w r
      | `Ok (Msg.Drain drain) when t.used_slots = 0 ->
          (* No work in flight? Mark as drained. *)
          Fut.Promise.set drain ()
      | `Ok (Msg.Drain drain) -> loop_drain [ drain ] t w r
      | `Ok (Msg.Completed { keys }) ->
          let locked_keys = CCList.fold_left (CCFun.flip Key_set.remove) t.locked_keys keys in
          let t = { t with used_slots = t.used_slots - 1; locked_keys } in
          exec_available_work w t >>= fun t -> loop t w r
      | `Closed -> Fut.return ()
  end

  type 'a t = {
    mutable draining : bool;
    w : 'a Msg.t Service.w;
  }

  let create ~slots f =
    let open Fut.Infix_monad in
    Service.create (Server.loop (Server.make slots f))
    >>= fun w -> Fut.return { draining = false; w }

  let enqueue { draining; w } ~keys task =
    if draining then Fut.return (Error `Closed)
    else
      let open Fut.Infix_monad in
      Channel.send w (Msg.Enqueue Task.{ keys; task })
      >>= function
      | `Ok () -> Fut.return (Ok ())
      | `Closed -> Fut.return (Error `Closed)

  let destroy { w; _ } = Channel.close w

  let drain_and_destroy ({ w; _ } as t) =
    let open Fut.Infix_monad in
    let d = Fut.Promise.create () in
    Channel.send w (Msg.Drain d)
    >>= function
    | `Ok () ->
        t.draining <- true;
        Fut.Promise.future d
    | `Closed -> Fut.return ()
end
