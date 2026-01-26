module Queue = CCFQueue

module Make (Fut : Abb_intf.Future.S) (Key : Map.OrderedType) (Time : Abb_time.Time_make(Fut).S) =
struct
  module Channel = Abb_channel.Make (Fut)
  module Service = Abb_service_local.Make (Fut)
  module Fc = Abb_future_combinators.Make (Fut)

  module Logger = struct
    type t = {
      exec_task : Key.t list -> unit;
      complete_task : Key.t list -> unit;
      work_done : Key.t list -> unit;
      running_tasks : int -> unit;
      suspended_tasks : int -> Key.t list Iter.t -> unit;
      suspend_task : Key.t list -> unit;
      unsuspend_task : Key.t list -> unit;
      enqueue : Key.t list -> unit;
      queue_time : float -> unit;
    }
  end

  module Name = struct
    type t = Key.t list [@@deriving ord]
  end

  module Name_map = CCMap.Make (Name)

  let rec is_prefix ~eq ~pre l =
    match (pre, l) with
    | c1 :: pre, c2 :: l when eq c1 c2 -> is_prefix ~eq ~pre l
    | _ :: _, _ :: _ -> false
    | [], _ :: _ -> true
    | _, [] -> false

  let is_key_prefix = is_prefix ~eq:(fun a b -> 0 = Key.compare a b)

  module Task = struct
    type t = Task : (Name.t * (unit -> 'a Fut.t) * 'a Fut.Promise.t * float) -> t
  end

  module Msg = struct
    type t =
      | Enqueue of Task.t
      | Suspend of Name.t
      | Unsuspend of Name.t
      | Work_done of Name.t
  end

  module Server = struct
    type t = {
      slots : int;
      running_tasks : Task.t Name_map.t;
      suspended_tasks : (int * Task.t) Name_map.t;
      queue : Task.t Queue.t;
      logger : Logger.t option;
    }

    let exec logger w (Task.Task (name, f, p, enqueued_at)) =
      let open Fut.Infix_monad in
      Time.monotonic ()
      >>= fun now ->
      let queue_time = now -. enqueued_at in
      CCOption.iter (fun { Logger.exec_task = log; _ } -> log name) logger;
      CCOption.iter (fun { Logger.queue_time = log; _ } -> log queue_time) logger;
      Fut.fork
        (let run =
           try
             Fut.await_bind
               (function
                 | `Det ret -> Fut.Promise.set p ret
                 | `Exn exn_bt -> Fut.Promise.set_exn p exn_bt
                 | `Aborted -> Fut.abort (Fut.Promise.future p))
               (f ())
           with exn ->
             let bt = Printexc.get_raw_backtrace () in
             Fut.Promise.set_exn p (exn, Some bt)
         in
         Fc.with_finally
           (fun () ->
             Fut.add_dep ~dep:run (Fut.Promise.future p);
             run)
           ~finally:(fun () ->
             CCOption.iter (fun { Logger.complete_task = log; _ } -> log name) logger;
             Channel.send w (Msg.Work_done name) >>= fun _ -> Fut.return ()))
      >>= fun _ -> Fut.return ()

    let rec exec_next_n_tasks remaining_slots w t =
      if 0 < remaining_slots then
        let open Fut.Infix_monad in
        match Queue.take_front t.queue with
        | Some ((Task.Task (n, _, _, _) as task), queue) ->
            let t = { t with queue; running_tasks = Name_map.add n task t.running_tasks } in
            exec t.logger w task >>= fun () -> exec_next_n_tasks (remaining_slots - 1) w t
        | None -> Fut.return t
      else Fut.return t

    let maybe_exec_task w t =
      let used_slots = Name_map.cardinal t.running_tasks in
      if used_slots < t.slots then exec_next_n_tasks (t.slots - used_slots) w t else Fut.return t

    let suspend_task name t =
      match Name_map.find_opt name t.running_tasks with
      | Some task ->
          {
            t with
            running_tasks = Name_map.remove name t.running_tasks;
            suspended_tasks = Name_map.add name (1, task) t.suspended_tasks;
          }
      | None ->
          {
            t with
            suspended_tasks =
              Name_map.update
                name
                (CCOption.map (fun (count, task) -> (count + 1, task)))
                t.suspended_tasks;
          }

    let unsuspend_task name t =
      match Name_map.find_opt name t.suspended_tasks with
      | Some (1, task) ->
          {
            t with
            running_tasks = Name_map.add name task t.running_tasks;
            suspended_tasks = Name_map.remove name t.suspended_tasks;
          }
      | Some (count, task) ->
          { t with suspended_tasks = Name_map.add name (count - 1, task) t.suspended_tasks }
      | None -> t

    let complete_task name t =
      {
        t with
        running_tasks = Name_map.remove name t.running_tasks;
        suspended_tasks = Name_map.remove name t.suspended_tasks;
      }

    let rec loop t w r =
      let open Fut.Infix_monad in
      Channel.recv r
      >>= function
      | `Ok (Msg.Enqueue task) ->
          let (Task.Task (n, _, _, _)) = task in
          CCOption.iter (fun { Logger.enqueue = log; _ } -> log n) t.logger;
          let t = { t with queue = Queue.snoc t.queue task } in
          maybe_exec_task w t
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; _ } -> log (Name_map.cardinal t.running_tasks))
            t.logger;
          CCOption.iter
            (fun { Logger.suspended_tasks = log; _ } ->
              log (Name_map.cardinal t.suspended_tasks) (Name_map.keys t.suspended_tasks))
            t.logger;
          loop t w r
      | `Ok (Msg.Suspend name) ->
          CCOption.iter (fun { Logger.suspend_task = log; _ } -> log name) t.logger;
          maybe_exec_task w (suspend_task name t)
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; _ } -> log (Name_map.cardinal t.running_tasks))
            t.logger;
          CCOption.iter
            (fun { Logger.suspended_tasks = log; _ } ->
              log (Name_map.cardinal t.suspended_tasks) (Name_map.keys t.suspended_tasks))
            t.logger;
          loop t w r
      | `Ok (Msg.Unsuspend name) ->
          CCOption.iter (fun { Logger.unsuspend_task = log; _ } -> log name) t.logger;
          maybe_exec_task w (unsuspend_task name t)
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; _ } -> log (Name_map.cardinal t.running_tasks))
            t.logger;
          CCOption.iter
            (fun { Logger.suspended_tasks = log; _ } ->
              log (Name_map.cardinal t.suspended_tasks) (Name_map.keys t.suspended_tasks))
            t.logger;
          loop t w r
      | `Ok (Msg.Work_done name) ->
          CCOption.iter (fun { Logger.work_done = log; _ } -> log name) t.logger;
          let t = complete_task name t in
          maybe_exec_task w t
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; exec_task; _ } ->
              log (Name_map.cardinal t.running_tasks))
            t.logger;
          CCOption.iter
            (fun { Logger.suspended_tasks = log; _ } ->
              log (Name_map.cardinal t.suspended_tasks) (Name_map.keys t.suspended_tasks))
            t.logger;
          loop t w r
      | `Closed -> Fut.return ()
  end

  type t = { w : Msg.t Service.w }

  let create ?logger ~slots () =
    let open Fut.Infix_monad in
    Service.create
      (Server.loop
         {
           Server.slots;
           running_tasks = Name_map.empty;
           suspended_tasks = Name_map.empty;
           queue = Queue.empty;
           logger;
         })
    >>= fun w -> Fut.return { w }

  let run ~name t f =
    let open Fut.Infix_monad in
    let p = Fut.Promise.create () in
    Time.monotonic ()
    >>= fun enqueued_at ->
    Channel.send t.w (Msg.Enqueue (Task.Task (name, f, p, enqueued_at)))
    >>= function
    | `Ok () -> Fut.Promise.future p
    | `Closed -> assert false

  let suspend ~name t =
    let open Fut.Infix_monad in
    Channel.send t.w (Msg.Suspend name)
    >>= function
    | `Ok () -> Fut.return ()
    | `Closed -> assert false

  let unsuspend ~name t =
    let open Fut.Infix_monad in
    Channel.send t.w (Msg.Unsuspend name)
    >>= function
    | `Ok () -> Fut.return ()
    | `Closed -> assert false
end
