module Service = Abb_service_local.Make (Abb)

(* ----- Round-trip: caller sees `Det. ---------------------------------- *)

module Msg_simple = struct
  type t = Run : (int, int) Service.Request.t -> t
end

let server_simple chan =
  let open Abb.Future.Infix_monad in
  let rec loop () =
    Abb.Chan.recv chan
    >>= function
    | Ok (Msg_simple.Run req) ->
        Service.respond req (fun () ->
            let v = Service.Request.payload req in
            Abb.Future.return (v * 2))
        >>= fun () -> loop ()
    | Error `Chan_closed -> Abb.Future.return ()
  in
  loop ()

let call_det =
  Oth.test ~desc:"call returns Ok of `Det response" ~name:"call det" (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_simple
        >>= fun s ->
        Service.call s (fun r -> Msg_simple.Run r) 21
        >>= fun r ->
        Abb.Chan.close s;
        Abb.Future.return r
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (Ok 42) -> ()
      | _ -> Oth.Assert.false_ "expected `Det (Ok 42)")

(* ----- Worker raises -> caller's future is in `Exn. ------------------- *)

exception Worker_failure

module Msg_exn = struct
  type t = Run : (unit, unit) Service.Request.t -> t
end

let server_exn chan =
  let open Abb.Future.Infix_monad in
  let rec loop () =
    Abb.Chan.recv chan
    >>= function
    | Ok (Msg_exn.Run req) ->
        Service.respond req (fun () -> raise Worker_failure) >>= fun () -> loop ()
    | Error `Chan_closed -> Abb.Future.return ()
  in
  loop ()

let call_exn =
  Oth.test ~desc:"worker exception propagates to caller as `Exn" ~name:"call exn" (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_exn
        >>= fun s ->
        Abb.Future.await (Service.call s (fun r -> Msg_exn.Run r) ())
        >>= fun terminal ->
        Abb.Chan.close s;
        Abb.Future.return terminal
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (`Exn (Worker_failure, _)) -> ()
      | _ -> Oth.Assert.false_ "expected `Det (`Exn (Worker_failure, _))")

(* ----- Worker aborts itself -> caller's future is in `Aborted. ------- *)

module Msg_abort = struct
  type t = Run : (unit, unit) Service.Request.t -> t
end

let server_abort chan =
  let open Abb.Future.Infix_monad in
  let rec loop () =
    Abb.Chan.recv chan
    >>= function
    | Ok (Msg_abort.Run req) ->
        Service.respond req (fun () ->
            let p = Abb.Future.Promise.create () in
            let f = Abb.Future.Promise.future p in
            Abb.Future.abort f >>= fun () -> f)
        >>= fun () -> loop ()
    | Error `Chan_closed -> Abb.Future.return ()
  in
  loop ()

let call_aborted =
  Oth.test ~desc:"worker abort propagates to caller as `Aborted" ~name:"call aborted" (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_abort
        >>= fun s ->
        Abb.Future.await (Service.call s (fun r -> Msg_abort.Run r) ())
        >>= fun terminal ->
        Abb.Chan.close s;
        Abb.Future.return terminal
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det `Aborted -> ()
      | _ -> Oth.Assert.false_ "expected `Det `Aborted")

(* ----- Caller-side abort: respond aborts the worker future. ---------- *)

(* When the caller aborts its [call] future mid-flight, [respond] races
   the worker against the caller-alive Chan and aborts the worker the
   moment that Chan closes.  This matches the pre-RFD-675 [Fut.add_dep]
   behavior and is what executors rely on for cancellation
   responsiveness.  The probe should observe that the worker reached its
   [started] line but never its [completed] line. *)

module Msg_slow = struct
  type t =
    | Run : (unit, unit) Service.Request.t -> t
    | Probe : (unit, bool) Service.Request.t -> t
end

let server_slow chan =
  let open Abb.Future.Infix_monad in
  let started = ref false in
  let completed = ref false in
  let rec loop () =
    Abb.Chan.recv chan
    >>= function
    | Ok (Msg_slow.Run req) ->
        Service.respond req (fun () ->
            started := true;
            Abb.Sys.sleep 0.20
            >>= fun () ->
            completed := true;
            Abb.Future.return ())
        >>= fun () -> loop ()
    | Ok (Msg_slow.Probe req) ->
        Service.respond req (fun () -> Abb.Future.return (!started && not !completed))
        >>= fun () -> loop ()
    | Error `Chan_closed -> Abb.Future.return ()
  in
  loop ()

let caller_abort_closes_reply =
  Oth.test ~desc:"caller abort aborts the worker future" ~name:"caller abort" (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_slow
        >>= fun s ->
        Abb.Future.fork (Service.call s (fun r -> Msg_slow.Run r) ())
        >>= fun call_fut ->
        Abb.Sys.sleep 0.02
        >>= fun () ->
        Abb.Future.abort call_fut
        >>= fun () ->
        (* Wait well past the worker's would-be sleep, so a non-aborted
           worker would have flipped [completed]. *)
        Abb.Sys.sleep 0.30
        >>= fun () ->
        Service.call s (fun r -> Msg_slow.Probe r) ()
        >>= fun r ->
        Abb.Chan.close s;
        Abb.Future.return r
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (Ok true) -> ()
      | _ -> Oth.Assert.false_ "expected `Det (Ok true)")

(* ----- Make_typed: typed GADT round-trip. ----------------------------- *)

module Req = struct
  type 'resp t =
    | Double : int -> int t
    | Stringify : int -> string t
end

module Typed = Service.Make_typed (Req)

let server_typed chan =
  let open Abb.Future.Infix_monad in
  let rec loop () =
    Abb.Chan.recv chan
    >>= function
    | Ok (Typed.Msg req) ->
        (match Service.Request.payload req with
          | Req.Double n -> Service.respond req (fun () -> Abb.Future.return (n * 2))
          | Req.Stringify n -> Service.respond req (fun () -> Abb.Future.return (string_of_int n)))
        >>= fun () -> loop ()
    | Error `Chan_closed -> Abb.Future.return ()
  in
  loop ()

let make_typed_roundtrip =
  Oth.test ~desc:"Make_typed.call returns typed results" ~name:"make_typed roundtrip" (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Typed.create server_typed
        >>= fun s ->
        Typed.call s (Req.Double 7)
        >>= fun a ->
        Typed.call s (Req.Stringify 42)
        >>= fun b ->
        Abb.Chan.close s;
        Abb.Future.return (a, b)
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (Ok 14, Ok "42") -> ()
      | _ -> Oth.Assert.false_ "expected `Det (Ok 14, Ok \"42\")")

(* Round-trip from an unpinned caller.  Regression for the [Chan.recv] /
   [Chan.send] slow-path bug where the loop-domain op resolved the
   caller's promise via [Future.run_with_state] directly, advancing the
   caller's [State.t] from the loop and tripping [ABB_FUT_DEBUG] when
   the caller was an unpinned task.  The fix routes the resolve through
   a [deliver] op carrying the caller's [unpinned_ctx]. *)

let call_from_unpinned =
  Oth.test
    ~desc:"call from an unpinned task body completes cleanly"
    ~name:"call from unpinned"
    (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_simple
        >>= fun s ->
        Abb.Task.run ~pinned:false (fun () ->
            Service.call s (fun r -> Msg_simple.Run r) 21
            >>= fun a ->
            Service.call s (fun r -> Msg_simple.Run r) 100 >>= fun b -> Abb.Future.return (a, b))
        >>= fun task_fut ->
        task_fut
        >>= fun pair ->
        Abb.Chan.close s;
        Abb.Future.return pair
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (Ok 42, Ok 200) -> ()
      | _ -> Oth.Assert.false_ "expected `Det (Ok 42, Ok 200)")

(* Stress regression for the slow-path cross-domain bug: many concurrent
   unpinned callers each issuing a tight loop of [Service.call]s.  When
   the slow-path resolves the caller's promise via [run_with_state]
   directly from the loop domain (the bug), the [ABB_FUT_DEBUG]
   owner-CAS will catch a window where the worker still holds the
   caller's state and abort the process with exit 134.  With the fix
   (resolve dispatched via [deliver] back to the caller's worker), this
   races cleanly. *)
let call_from_unpinned_stress =
  Oth.test
    ~desc:"many concurrent unpinned callers race the slow-path resolve"
    ~name:"call from unpinned stress"
    (fun _ ->
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create server_simple
        >>= fun s ->
        let one_caller n =
          Abb.Task.run ~pinned:false (fun () ->
              let rec loop k acc =
                if k = 0 then Abb.Future.return acc
                else
                  Service.call s (fun r -> Msg_simple.Run r) k
                  >>= function
                  | Ok v -> loop (k - 1) (acc + v)
                  | Error `Chan_closed -> Abb.Future.return acc
              in
              loop n 0)
          >>= fun task_fut -> task_fut
        in
        let module Fc = Abb_future_combinators.Make (Abb.Future) in
        Fc.List.iter_par ~f:(fun _ -> one_caller 25 >>| fun _ -> ()) (CCList.init 16 CCFun.id)
        >>= fun () ->
        Abb.Chan.close s;
        Abb.Future.return ()
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det () -> ()
      | _ -> Oth.Assert.false_ "expected `Det ()")

(* ----- Service is closed before caller sends. ------------------------- *)

let call_after_close =
  Oth.test
    ~desc:"call returns Error Chan_closed if the service is closed"
    ~name:"call after close"
    (fun _ ->
      let body chan =
        Abb.Chan.close chan;
        Abb.Future.return ()
      in
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create body
        >>= fun s -> Abb.Sys.sleep 0.01 >>= fun () -> Service.call s (fun r -> Msg_simple.Run r) 0
      in
      match Abb.Scheduler.run_with_state (fun _ -> fut) with
      | `Det (Error `Chan_closed) -> ()
      | _ -> Oth.Assert.false_ "expected `Det (Error `Chan_closed)")

let () =
  Random.self_init ();
  Oth.run
    ~file:__FILE__
    (Oth.parallel
       [
         call_det;
         call_exn;
         call_aborted;
         caller_abort_closes_reply;
         make_typed_roundtrip;
         call_after_close;
         call_from_unpinned;
         call_from_unpinned_stress;
       ])
