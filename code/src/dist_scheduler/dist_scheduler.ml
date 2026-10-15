type err_kind =
  | Create
  | Fetch
  | Store
  | Update
  | Delete
  | Tx
[@@deriving show]

type err = {
  kind : err_kind;
  msg : string;
}
[@@deriving show]

type dist_sched_err = [ `Dist_sched_err of err ] [@@deriving show]

module type S = sig
  module Task : sig
    type 'a t
  end

  module Store : sig
    type t
    type tx
    type opts
    type stored
    type minted
    type id

    val create : opts -> (t, [> dist_sched_err ]) result Abb.Future.t
    val fetch_next : tx -> (stored Task.t option, [> dist_sched_err ]) result Abb.Future.t
    val destroy : t -> unit Abb.Future.t
    val tx : t -> (tx -> 'a Abb.Future.t) -> ('a, [> dist_sched_err ]) result Abb.Future.t

    module Task : sig
      val store : tx -> minted Task.t -> (stored Task.t, [> dist_sched_err ]) result Abb.Future.t
      val update : tx -> stored Task.t -> (unit, [> dist_sched_err ]) result Abb.Future.t
      val delete : tx -> stored Task.t -> (unit, [> dist_sched_err ]) result Abb.Future.t
      val fetch : tx -> id -> (stored Task.t option, [> dist_sched_err ]) result Abb.Future.t
    end
  end

  val run : Store.tx -> Store.stored Task.t -> unit Abb.Future.t
end

module type T = sig
  type t
  type opts
  type id
  type stored
  type minted

  val start : name:string -> wait:(unit -> unit Abb.Future.t) -> opts -> t Abb.Future.t
  val stop : t -> unit Abb.Future.t
  val store : t -> minted -> (stored, [> dist_sched_err ]) result Abb.Future.t
  val update : t -> stored -> (unit, [> dist_sched_err ]) result Abb.Future.t
  val delete : t -> stored -> (unit, [> dist_sched_err ]) result Abb.Future.t
  val fetch : t -> id -> (stored option, [> dist_sched_err ]) result Abb.Future.t
end

module Make (S : S) = struct
  module Sl = Abbs_service_local

  type opts = S.Store.opts
  type id = S.Store.id
  type stored = S.Store.stored S.Task.t
  type minted = S.Store.minted S.Task.t

  (* Each public function maps to a request sent to the local service.  Per RFD 675 the reply path
     lives inside the request envelope (an [Sl.Request.t] carrying its own reply channel) rather than
     in a raw promise embedded in the message, which would race across tasks. *)
  module Msg = struct
    type t =
      (* Internal message: an iteration of the scheduler is due. *)
      | Iter
      | Stop of (unit, unit) Sl.Request.t
      | Store of (minted, (stored, dist_sched_err) result) Sl.Request.t
      | Update of (stored, (unit, dist_sched_err) result) Sl.Request.t
      | Delete of (stored, (unit, dist_sched_err) result) Sl.Request.t
      | Fetch of (id, (stored option, dist_sched_err) result) Sl.Request.t
  end

  type t = Msg.t Sl.t

  module Server = struct
    (* Run the wait function and, when it returns, signal the server that an iteration is due. *)
    let wait_and_iter ~wait chan =
      let open Abb.Future.Infix_monad in
      wait () >>= fun () -> Sl.notify chan Msg.Iter >>= fun _ -> Abb.Future.return ()

    (* Fetch and dispatch the next task in its own transaction, repeating until the store has no more
       tasks to hand out (or a fetch fails). *)
    let rec drain store =
      let open Abb.Future.Infix_monad in
      S.Store.tx store (fun tx ->
          S.Store.fetch_next tx
          >>= function
          | Ok (Some task) -> S.run tx task >>= fun () -> Abb.Future.return `Continue
          | Ok None -> Abb.Future.return `Done
          | Error _ -> Abb.Future.return `Done)
      >>= function
      | Ok `Continue -> drain store
      | Ok `Done -> Abb.Future.return ()
      | Error _ -> Abb.Future.return ()

    (* Create a store, run [f] with the (possibly failed) creation result, and destroy the store
       afterwards even if [f] fails or is aborted. *)
    let with_store_created ~opts f =
      Abbs_fc.protect_finally
        ~setup:(fun () -> S.Store.create opts)
        ~finally:(function
          | Ok store -> S.Store.destroy store
          | Error _ -> Abb.Future.return ())
        f

    (* Run a single data operation [f] inside a transaction on a freshly-created store, return its
       result, and tear the store down. Failures (store creation or transaction setup) become an
       [err] of the operation's [kind]. *)
    let run_op ~opts ~kind f =
      let open Abb.Future.Infix_monad in
      with_store_created ~opts (function
        | Ok store -> (
            S.Store.tx store f
            >>= function
            | Ok result -> Abb.Future.return result
            | Error (`Dist_sched_err { msg; _ }) ->
                Abbs_fc.return_err (`Dist_sched_err { kind; msg }))
        | Error _ ->
            Abbs_fc.return_err
              (`Dist_sched_err { kind; msg = "dist_scheduler: could not create store" }))

    (* Run a data operation for [req] and reply to the caller, leaving the loop running. *)
    let respond_op ~opts ~kind req f =
      let open Abb.Future.Infix_monad in
      Sl.respond req (fun () -> run_op ~opts ~kind f) >>= fun () -> Abb.Future.return `Continue

    (* Handle one message, returning [`Stop] when the loop should terminate and [`Continue]
       otherwise. *)
    let handle_msg ~wait ~opts chan =
      let open Abb.Future.Infix_monad in
      function
      | Msg.Iter ->
          (* Drain all currently-available tasks, then re-arm the wait loop. *)
          with_store_created ~opts (function
            | Ok store -> drain store
            | Error _ -> Abb.Future.return ())
          >>= fun () ->
          Abb.Future.fork (wait_and_iter ~wait chan) >>= fun _ -> Abb.Future.return `Continue
      | Msg.Stop req ->
          (* Reply to the caller and tell the loop to terminate, which closes the channel and lets
             any in-flight wait fork wind down. *)
          Sl.respond req (fun () -> Abb.Future.return ()) >>= fun () -> Abb.Future.return `Stop
      | Msg.Store req ->
          respond_op ~opts ~kind:Store req (fun tx ->
              S.Store.Task.store tx (Sl.Request.payload req))
      | Msg.Update req ->
          respond_op ~opts ~kind:Update req (fun tx ->
              S.Store.Task.update tx (Sl.Request.payload req))
      | Msg.Delete req ->
          respond_op ~opts ~kind:Delete req (fun tx ->
              S.Store.Task.delete tx (Sl.Request.payload req))
      | Msg.Fetch req ->
          respond_op ~opts ~kind:Fetch req (fun tx ->
              S.Store.Task.fetch tx (Sl.Request.payload req))

    let rec loop ~wait ~opts chan =
      let open Abb.Future.Infix_monad in
      Abb.Chan.recv chan
      >>= function
      | Ok msg -> (
          handle_msg ~wait ~opts chan msg
          >>= function
          | `Continue -> loop ~wait ~opts chan
          | `Stop -> Abb.Future.return ())
      | Error `Chan_closed -> Abb.Future.return ()

    let run ~wait ~opts chan =
      let open Abb.Future.Infix_monad in
      Abb.Future.fork (wait_and_iter ~wait chan) >>= fun _ -> loop ~wait ~opts chan
  end

  let start ~name ~wait opts = Sl.create ~name (Server.run ~wait ~opts)

  let stop t =
    let open Abb.Future.Infix_monad in
    Sl.call t (fun req -> Msg.Stop req) ()
    >>= function
    | Ok () | Error `Chan_closed -> Abb.Future.return ()

  let closed_err kind = Error (`Dist_sched_err { kind; msg = "dist_scheduler: service closed" })

  (* Widen a service response's closed error type to the open row exposed by the public signature. *)
  let widen = function
    | Ok v -> Ok v
    | Error (`Dist_sched_err err) -> Error (`Dist_sched_err err)

  let store t minted =
    let open Abb.Future.Infix_monad in
    Sl.call t (fun req -> Msg.Store req) minted
    >>= function
    | Ok result -> Abb.Future.return (widen result)
    | Error `Chan_closed -> Abb.Future.return (closed_err Store)

  let update t stored =
    let open Abb.Future.Infix_monad in
    Sl.call t (fun req -> Msg.Update req) stored
    >>= function
    | Ok result -> Abb.Future.return (widen result)
    | Error `Chan_closed -> Abb.Future.return (closed_err Update)

  let delete t stored =
    let open Abb.Future.Infix_monad in
    Sl.call t (fun req -> Msg.Delete req) stored
    >>= function
    | Ok result -> Abb.Future.return (widen result)
    | Error `Chan_closed -> Abb.Future.return (closed_err Delete)

  let fetch t id =
    let open Abb.Future.Infix_monad in
    Sl.call t (fun req -> Msg.Fetch req) id
    >>= function
    | Ok result -> Abb.Future.return (widen result)
    | Error `Chan_closed -> Abb.Future.return (closed_err Fetch)
end
