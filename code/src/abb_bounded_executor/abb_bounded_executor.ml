module Queue : sig
  type 'a t

  val empty : 'a t
  val enqueue : 'a -> 'a t -> 'a t
  val dequeue : 'a t -> ('a * 'a t) option
end = struct
  type 'a t = {
    front : 'a list;
    rear : 'a list;
  }

  let empty = { front = []; rear = [] }
  let enqueue v t = { t with rear = v :: t.rear }

  let rec dequeue = function
    | { front = []; rear = [] } -> None
    | { front = v :: rest; rear } -> Some (v, { front = rest; rear })
    | { front = []; rear = _ :: _ as rear } -> dequeue { front = CCList.rev rear; rear = [] }
end

module Make (S : Abb_intf.S) (Key : Map.OrderedType) (Time : Abb_time.Time_make(S.Future).S) =
struct
  module Fut = S.Future
  module Service = Abb_service_local.Make (S)
  module Fc = Abb_future_combinators.Make (Fut)

  module Logger = struct
    type t = {
      exec_task : Key.t list -> unit;
      complete_task : Key.t list -> unit;
      work_done : Key.t list -> unit;
      running_tasks : int -> unit;
      enqueue : Key.t list -> unit;
      queue_time : float -> unit;
    }
  end

  module Name = struct
    type t = Key.t list
  end

  module Task_id = struct
    type t = int

    let compare = CCInt.compare
  end

  module Task_id_map = CCMap.Make (Task_id)

  module Task = struct
    type t =
      | Task : {
          name : Name.t;
          req : (unit -> 'a Fut.t, 'a) Service.Request.t;
          enqueued_at : float;
        }
          -> t
  end

  module Msg = struct
    type t =
      | Enqueue of Task.t
      | Work_done of Task_id.t * Name.t
  end

  module Server = struct
    type t = {
      slots : int;
      running_tasks : Task.t Task_id_map.t;
      queue : (Task_id.t * Task.t) Queue.t;
      logger : Logger.t option;
      next_id : int;
    }

    let exec logger w id (Task.Task { name; req; enqueued_at }) =
      let open Fut.Infix_monad in
      Time.monotonic ()
      >>= fun now ->
      let queue_time = now -. enqueued_at in
      CCOption.iter (fun { Logger.exec_task = log; _ } -> log name) logger;
      CCOption.iter (fun { Logger.queue_time = log; _ } -> log queue_time) logger;
      Fut.fork
        (Fc.with_finally
           (fun () -> Service.respond req (fun () -> Service.Request.payload req ()))
           ~finally:(fun () ->
             CCOption.iter (fun { Logger.complete_task = log; _ } -> log name) logger;
             S.Chan.send w (Msg.Work_done (id, name)) >>= fun _ -> Fut.return ()))
      >>= fun _ -> Fut.return ()

    let rec exec_next_n_tasks remaining_slots w t =
      if 0 < remaining_slots then
        let open Fut.Infix_monad in
        match Queue.dequeue t.queue with
        | Some ((id, task), queue) ->
            let t = { t with queue; running_tasks = Task_id_map.add id task t.running_tasks } in
            exec t.logger w id task >>= fun () -> exec_next_n_tasks (remaining_slots - 1) w t
        | None -> Fut.return t
      else Fut.return t

    let maybe_exec_task w t =
      let used_slots = Task_id_map.cardinal t.running_tasks in
      if used_slots < t.slots then exec_next_n_tasks (t.slots - used_slots) w t else Fut.return t

    let complete_task id t = { t with running_tasks = Task_id_map.remove id t.running_tasks }

    let rec loop t chan =
      let open Fut.Infix_monad in
      S.Chan.recv chan
      >>= function
      | Ok (Msg.Enqueue task) ->
          let (Task.Task { name; _ }) = task in
          CCOption.iter (fun { Logger.enqueue = log; _ } -> log name) t.logger;
          let id = t.next_id in
          let t = { t with next_id = t.next_id + 1; queue = Queue.enqueue (id, task) t.queue } in
          maybe_exec_task chan t
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; _ } -> log (Task_id_map.cardinal t.running_tasks))
            t.logger;
          loop t chan
      | Ok (Msg.Work_done (id, name)) ->
          CCOption.iter (fun { Logger.work_done = log; _ } -> log name) t.logger;
          let t = complete_task id t in
          maybe_exec_task chan t
          >>= fun t ->
          CCOption.iter
            (fun { Logger.running_tasks = log; _ } -> log (Task_id_map.cardinal t.running_tasks))
            t.logger;
          loop t chan
      | Error `Chan_closed -> Fut.return ()
  end

  type t = Msg.t Service.t

  let create ?logger ~slots () =
    (* The internal queue lives inside [Server.t], so the service Chan
       only carries [Enqueue]/[Work_done] traffic.  Pick a capacity that
       comfortably absorbs bursts without parking callers on the [run]
       enqueue path (which would replace the old fire-and-forget
       semantics with backpressure). *)
    Service.create
      ~capacity:100_000
      (Server.loop
         {
           Server.slots;
           running_tasks = Task_id_map.empty;
           queue = Queue.empty;
           logger;
           next_id = 0;
         })

  let run ?(name = []) t f =
    let open Fut.Infix_monad in
    Time.monotonic ()
    >>= fun enqueued_at ->
    Service.call t (fun req -> Msg.Enqueue (Task.Task { name; req; enqueued_at })) f
    >>= function
    | Ok v -> Fut.return v
    | Error `Chan_closed -> assert false
end
