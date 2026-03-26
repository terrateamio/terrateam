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

module Make (Fut : Abb_intf.Future.S) = struct
  module Channel = Abb_channel.Make (Fut)
  module Service = Abb_service_local.Make (Fut)

  module Task = struct
    type t = Task : ((unit -> 'a Fut.t) * 'a Fut.Promise.t) -> t
  end

  module Msg = struct
    type t =
      | Enqueue of Task.t
      | Work_done
  end

  module Server = struct
    type t = {
      slots : int;
      used_slots : int;
      queue : Task.t Queue.t;
    }

    let exec w (Task.Task (f, p)) =
      let open Fut.Infix_monad in
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
         run >>= fun () -> Channel.send w Msg.Work_done >>= fun _ -> Fut.return ())
      >>= fun _ -> Fut.return ()

    let rec exec_work w =
      let open Fut.Infix_monad in
      function
      | { used_slots = 0; _ } as t -> Fut.return t
      | t -> (
          match Queue.dequeue t.queue with
          | Some (task, queue) ->
              let t = { t with used_slots = t.used_slots - 1; queue } in
              exec w task >>= fun () -> exec_work w t
          | None -> Fut.return t)

    let rec loop t w r =
      let open Fut.Infix_monad in
      Channel.recv r
      >>= function
      | `Ok (Msg.Enqueue task) ->
          let t = { t with queue = Queue.enqueue task t.queue } in
          exec_work w t >>= fun t -> loop t w r
      | `Ok Msg.Work_done ->
          let t = { t with used_slots = t.used_slots - 1 } in
          exec_work w t >>= fun t -> loop t w r
      | `Closed -> Fut.return ()
  end

  type t = { w : Msg.t Service.w }

  let create ~slots () =
    let open Fut.Infix_monad in
    Service.create (Server.loop { Server.slots; used_slots = 0; queue = Queue.empty })
    >>= fun w -> Fut.return { w }

  let run t f =
    let open Fut.Infix_monad in
    let p = Fut.Promise.create () in
    Channel.send t.w (Msg.Enqueue (Task.Task (f, p)))
    >>= function
    | `Ok () -> Fut.Promise.future p
    | `Closed -> assert false
end
