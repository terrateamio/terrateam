module Fut = Abb_fut.Make (struct
  type t = unit
  type data = int

  let zero_data = 0
end)

open Fut.Infix_monad

let drive fut =
  let state = Abb_fut.State.create () in
  ignore (Fut.run_with_state fut state)

let p1 =
  Oth.test ~desc:"set_data flows through immediate get_data" ~name:"P1" (fun _ ->
      let r = ref None in
      let fut =
        Fut.set_data 1
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        r := Some v;
        Fut.return ()
      in
      drive fut;
      assert (!r = Some 1))

let p2 =
  Oth.test ~desc:"set_data flows through nested return chain" ~name:"P2" (fun _ ->
      let r = ref None in
      let fut =
        Fut.set_data 1
        >>= fun () ->
        Fut.return "foo"
        >>= fun _ ->
        Fut.get_data ()
        >>= fun v ->
        r := Some v;
        Fut.return ()
      in
      drive fut;
      assert (!r = Some 1))

let default_data =
  Oth.test ~desc:"untouched chain reads zero_data" ~name:"Default" (fun _ ->
      let r = ref None in
      let fut =
        Fut.get_data ()
        >>= fun v ->
        r := Some v;
        Fut.return ()
      in
      drive fut;
      assert (!r = Some 0))

let promise_observer_keeps_own_data =
  Oth.test
    ~desc:"observer of a promise keeps its own chain data; setter's data does not leak"
    ~name:"Promise observer own data"
    (fun _ ->
      let open Fut.Infix_monad in
      let state = Abb_fut.State.create () in
      let p = Fut.Promise.create () in
      let r = ref None in
      (* Observer never calls set_data, so its chain data is [zero_data = 0]. *)
      let observer =
        Fut.Promise.future p
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        r := Some v;
        Fut.return ()
      in
      (* Setter sets its own chain data to 7 and resolves the promise.  The
         observer should NOT see 7 on the resume — chains are isolated. *)
      let setter = Fut.set_data 7 >>= fun () -> Fut.Promise.set p () in
      ignore (Fut.run_with_state observer state);
      ignore (Fut.run_with_state setter state);
      assert (!r = Some 0))

let fork_isolation =
  Oth.test ~desc:"forked chains see their own data" ~name:"Fork isolation" (fun _ ->
      let state = Abb_fut.State.create () in
      let p_a = Fut.Promise.create () in
      let p_b = Fut.Promise.create () in
      let r_a = ref None in
      let r_b = ref None in
      let chain_a =
        Fut.set_data 11
        >>= fun () ->
        Fut.Promise.future p_a
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        r_a := Some v;
        Fut.return ()
      in
      let chain_b =
        Fut.set_data 22
        >>= fun () ->
        Fut.Promise.future p_b
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        r_b := Some v;
        Fut.return ()
      in
      ignore (Fut.run_with_state chain_a state);
      ignore (Fut.run_with_state chain_b state);
      ignore (Fut.run_with_state (Fut.Promise.set p_a ()) state);
      ignore (Fut.run_with_state (Fut.Promise.set p_b ()) state);
      assert (!r_a = Some 11);
      assert (!r_b = Some 22))

(* Two chains run concurrently, each goes through several [set_data]/[get_data] steps, and
   pauses on a promise between them.  We drive their resumes in interleaved order to prove
   that the [data] each chain sees is its own — not whatever the other chain happened to set
   most recently before suspending. *)
let concurrent_bind_isolation =
  Oth.test
    ~desc:"interleaved chains keep their own data across each bind step"
    ~name:"Concurrent bind isolation"
    (fun _ ->
      let state = Abb_fut.State.create () in
      let trace_a = ref [] in
      let trace_b = ref [] in
      let record r v = r := v :: !r in
      let pause_a1 = Fut.Promise.create () in
      let pause_a2 = Fut.Promise.create () in
      let pause_b1 = Fut.Promise.create () in
      let pause_b2 = Fut.Promise.create () in
      let chain_a =
        Fut.set_data 11
        >>= fun () ->
        Fut.Promise.future pause_a1
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        record trace_a (`After_first v);
        Fut.set_data 12
        >>= fun () ->
        Fut.Promise.future pause_a2
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        record trace_a (`After_second v);
        Fut.return ()
      in
      let chain_b =
        Fut.set_data 21
        >>= fun () ->
        Fut.Promise.future pause_b1
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        record trace_b (`After_first v);
        Fut.set_data 22
        >>= fun () ->
        Fut.Promise.future pause_b2
        >>= fun () ->
        Fut.get_data ()
        >>= fun v ->
        record trace_b (`After_second v);
        Fut.return ()
      in
      ignore (Fut.run_with_state chain_a state);
      ignore (Fut.run_with_state chain_b state);
      (* Resumes interleave: A1, B1, A2, B2.  Between A1 and A2, chain B has run a step
         that wrote 21 (and then 22).  If chain data leaked, A would observe B's writes. *)
      ignore (Fut.run_with_state (Fut.Promise.set pause_a1 ()) state);
      ignore (Fut.run_with_state (Fut.Promise.set pause_b1 ()) state);
      ignore (Fut.run_with_state (Fut.Promise.set pause_a2 ()) state);
      ignore (Fut.run_with_state (Fut.Promise.set pause_b2 ()) state);
      assert (List.rev !trace_a = [ `After_first 11; `After_second 12 ]);
      assert (List.rev !trace_b = [ `After_first 21; `After_second 22 ]))

let () =
  Oth.(
    run
      ~file:__FILE__
      (parallel
         [
           p1;
           p2;
           default_data;
           promise_observer_keeps_own_data;
           fork_isolation;
           concurrent_bind_isolation;
         ]))
