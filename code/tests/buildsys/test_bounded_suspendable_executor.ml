module Hmap = Hmap.Make (struct
  type 'a t = string
end)

module Fut = Abb_fut.Make (struct
  type t = unit
end)

module Fc = Abb_future_combinators.Make (Fut)

module Time = struct
  let time () = Fut.return (Unix.gettimeofday ())
  let monotonic () = Fut.return (Unix.gettimeofday ())
end

module Exec = Abb_bounded_suspendable_executor.Make (Fut) (CCString) (Time)

let dummy_state = Abb_fut.State.create ()

module Pp = struct
  type 'a t =
    [ `Det of 'a
    | `Undet
    | `Aborted
    | `Exn of (exn * Printexc.raw_backtrace option[@opaque] [@equal ( = )])
    ]
  [@@deriving eq, show]
end

module Pp_int = struct
  type t = int Pp.t [@@deriving eq, show]
end

module Pp_unit = struct
  type t = unit Pp.t [@@deriving eq, show]
end

let make_logger () =
  let running_tasks_count = ref 0 in
  let suspended_tasks_count = ref 0 in
  let logger =
    {
      Exec.Logger.exec_task = (fun _ -> ());
      complete_task = (fun _ -> ());
      work_done = (fun _ -> ());
      running_tasks = (fun n -> running_tasks_count := n);
      suspended_tasks = (fun n _ -> suspended_tasks_count := n);
      suspend_task = (fun _ -> ());
      unsuspend_task = (fun _ -> ());
      enqueue = (fun _ -> ());
      queue_time = (fun _ -> ());
    }
  in
  (logger, running_tasks_count, suspended_tasks_count)

module Builder = struct
  module Key_repr = struct
    type t = {
      key : Hmap.Key.t;
      name : string;
    }

    let equal a b = Hmap.Key.equal a.key b.key
    let to_string k = k.name
  end

  type 'v k = 'v Hmap.key

  let key_repr_of_key k = { Key_repr.key = Hmap.Key.hide_type k; name = Hmap.Key.info k }

  module C = struct
    type 'a t = 'a Fut.t

    let return = Fut.return
    let ( >>= ) = Fut.Infix_monad.( >>= )
    let with_finally f ~finally = Fc.with_finally f ~finally
  end

  module Queue = struct
    type t = Exec.t

    let run ~name t f =
      let name_str = Key_repr.to_string name in
      Exec.run ~name:[ name_str ] t f

    let suspend ~name t =
      let name_str = Key_repr.to_string name in
      Exec.suspend ~name:[ name_str ] t

    let unsuspend ~name t =
      let name_str = Key_repr.to_string name in
      Exec.unsuspend ~name:[ name_str ] t
  end

  module Notify = struct
    type t = (unit Fut.t * unit Fut.Promise.t) ref

    let create () =
      let p = Fut.Promise.create () in
      let fut = Fut.Promise.future p in
      ref (fut, p)

    let notify t =
      let open Fut.Infix_monad in
      let _, notify = !t in
      let p = Fut.Promise.create () in
      let fut = Fut.Promise.future p in
      t := (fut, p);
      Fut.Promise.set notify () >>= fun () -> Fut.return ()

    let wait t =
      let open Fut.Infix_monad in
      let wait, _ = !t in
      wait >>= fun () -> Fut.return ()
  end

  module State = struct
    type t = Hmap.t ref

    let set_k t k v =
      t := Hmap.add k v !t;
      C.return ()

    let get_k t k =
      match Hmap.find k !t with
      | Some v -> C.return v
      | None -> failwith "Key not found"

    let get_k_opt t k = C.return (Hmap.find k !t)
  end
end

module Bs = Buildsys.Make (Builder)

external coerce : 'a Hmap.key -> 'a Bs.Task.t Hmap.key = "%identity"

let rebuilder = { Bs.Rebuilder.run = (fun _st _k _v -> Builder.C.return false) }

let tests =
  [
    Oth.test ~name:"Const" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let a1 : int Hmap.key = Hmap.Key.create "a1" in
        let state = Hmap.empty |> Hmap.add a1 10 in
        let st = Bs.St.create (ref state) in
        let tasks_map = Hmap.empty in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 () >>= fun queue -> Bs.build queue rebuilder tasks a1 st
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq ~eq:Pp_int.equal ~pp:Pp_int.pp (Fut.state run) (`Det 10);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0);
    Oth.test ~name:"Task throws an exception" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let a1 : int Hmap.key = Hmap.Key.create "a1" in
        let st = Bs.St.create (ref Hmap.empty) in
        let tasks_map =
          Hmap.empty |> Hmap.add (coerce a1) (fun _ _ _ -> raise (Failure "test exception"))
        in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 () >>= fun queue -> Bs.build queue rebuilder tasks a1 st
        in
        ignore (Fut.run_with_state run dummy_state);
        (match Fut.state run with
        | `Exn _ -> ()
        | _ -> Oth.Assert.false_ "Expected `Exn");
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0);
    Oth.test ~name:"Build aborted" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let a1 : int Hmap.key = Hmap.Key.create "a1" in
        let st = Bs.St.create (ref Hmap.empty) in
        let trigger = Fut.Promise.create () in
        let work_started = Fut.Promise.create () in
        let tasks_map =
          Hmap.empty
          |> Hmap.add (coerce a1) (fun _ _ _ ->
                 let open Fut.Infix_monad in
                 Fut.Promise.set work_started ()
                 >>= fun () -> Fut.Promise.future trigger >>= fun () -> Fut.return 10)
        in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 () >>= fun queue -> Bs.build queue rebuilder tasks a1 st
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future work_started))
          (`Det ());
        Oth.Assert.eq ~eq:Pp_int.equal ~pp:Pp_int.pp (Fut.state run) `Undet;
        ignore (Fut.run_with_state (Fut.abort run) dummy_state);
        Oth.Assert.eq ~eq:Pp_int.equal ~pp:Pp_int.pp (Fut.state run) `Aborted;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future trigger))
          `Aborted;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0);
    Oth.test ~name:"Suspended tasks cleaned up on exn" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let a1 : int Hmap.key = Hmap.Key.create "a1" in
        let b1 : int Hmap.key = Hmap.Key.create "b1" in
        let st = Bs.St.create (ref Hmap.empty) in
        let tasks_map =
          Hmap.empty
          |> Hmap.add (coerce a1) (fun _ _ _ -> raise (Failure "test exception"))
          |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } ->
                 let open Fut.Infix_monad in
                 fetch a1 >>= fun v -> Fut.return (v + 1))
        in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 () >>= fun queue -> Bs.build queue rebuilder tasks b1 st
        in
        ignore (Fut.run_with_state run dummy_state);
        (match Fut.state run with
        | `Exn _ -> ()
        | _ -> Oth.Assert.false_ "Expected `Exn");
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0);
    Oth.test ~name:"Suspended tasks cleaned up on exn on concurrent fetch" (fun _ ->
        (* 4 layers deep: root -> 2 -> 4 -> 8 leaf tasks
           Leaves wait on triggers, one throws exception *)
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let st = Bs.St.create (ref Hmap.empty) in
        (* Layer 1: root *)
        let root : int Hmap.key = Hmap.Key.create "root" in
        (* Layer 2: 2 tasks *)
        let l2_0 : int Hmap.key = Hmap.Key.create "l2_0" in
        let l2_1 : int Hmap.key = Hmap.Key.create "l2_1" in
        (* Layer 3: 4 tasks *)
        let l3_0 : int Hmap.key = Hmap.Key.create "l3_0" in
        let l3_1 : int Hmap.key = Hmap.Key.create "l3_1" in
        let l3_2 : int Hmap.key = Hmap.Key.create "l3_2" in
        let l3_3 : int Hmap.key = Hmap.Key.create "l3_3" in
        (* Layer 4 (leaves): 8 tasks *)
        let leaf_0 : int Hmap.key = Hmap.Key.create "leaf_0" in
        let leaf_1 : int Hmap.key = Hmap.Key.create "leaf_1" in
        let leaf_2 : int Hmap.key = Hmap.Key.create "leaf_2" in
        let leaf_3 : int Hmap.key = Hmap.Key.create "leaf_3" in
        let leaf_4 : int Hmap.key = Hmap.Key.create "leaf_4" in
        let leaf_5 : int Hmap.key = Hmap.Key.create "leaf_5" in
        let leaf_6 : int Hmap.key = Hmap.Key.create "leaf_6" in
        let leaf_7 : int Hmap.key = Hmap.Key.create "leaf_7" in
        (* Triggers and started promises for leaves *)
        let leaf_triggers = Array.init 8 (fun _ -> Fut.Promise.create ()) in
        let leaf_started = Array.init 8 (fun _ -> Fut.Promise.create ()) in
        let make_leaf_task idx throws_exn =
         fun _ _ _ ->
          let open Fut.Infix_monad in
          Fut.Promise.set leaf_started.(idx) ()
          >>= fun () ->
          Fut.Promise.future leaf_triggers.(idx)
          >>= fun () -> if throws_exn then raise (Failure "test exception") else Fut.return 1
        in
        let make_branch_task left right =
         fun _ _ { Bs.Fetcher.fetch } ->
          let open Fut.Infix_monad in
          Fc.all2 (fetch left) (fetch right) >>= fun (v1, v2) -> Fut.return (v1 + v2)
        in
        let tasks_map =
          Hmap.empty
          (* Leaves - leaf_0 throws exception *)
          |> Hmap.add (coerce leaf_0) (make_leaf_task 0 true)
          |> Hmap.add (coerce leaf_1) (make_leaf_task 1 false)
          |> Hmap.add (coerce leaf_2) (make_leaf_task 2 false)
          |> Hmap.add (coerce leaf_3) (make_leaf_task 3 false)
          |> Hmap.add (coerce leaf_4) (make_leaf_task 4 false)
          |> Hmap.add (coerce leaf_5) (make_leaf_task 5 false)
          |> Hmap.add (coerce leaf_6) (make_leaf_task 6 false)
          |> Hmap.add (coerce leaf_7) (make_leaf_task 7 false)
          (* Layer 3 *)
          |> Hmap.add (coerce l3_0) (make_branch_task leaf_0 leaf_1)
          |> Hmap.add (coerce l3_1) (make_branch_task leaf_2 leaf_3)
          |> Hmap.add (coerce l3_2) (make_branch_task leaf_4 leaf_5)
          |> Hmap.add (coerce l3_3) (make_branch_task leaf_6 leaf_7)
          (* Layer 2 *)
          |> Hmap.add (coerce l2_0) (make_branch_task l3_0 l3_1)
          |> Hmap.add (coerce l2_1) (make_branch_task l3_2 l3_3)
          (* Root *)
          |> Hmap.add (coerce root) (make_branch_task l2_0 l2_1)
        in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:20 () >>= fun queue -> Bs.build queue rebuilder tasks root st
        in
        ignore (Fut.run_with_state run dummy_state);
        (* Verify all leaves have started *)
        for i = 0 to 7 do
          Oth.Assert.eq
            ~eq:Pp_unit.equal
            ~pp:Pp_unit.pp
            (Fut.state (Fut.Promise.future leaf_started.(i)))
            (`Det ())
        done;
        (* 8 leaves running, 7 branch tasks suspended (1 root + 2 l2 + 4 l3) *)
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 8;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 7;
        Oth.Assert.eq ~eq:Pp_int.equal ~pp:Pp_int.pp (Fut.state run) `Undet;
        (* Trigger leaf_0 to throw exception *)
        ignore (Fut.run_with_state (Fut.Promise.set leaf_triggers.(0) ()) dummy_state);
        (match Fut.state run with
        | `Exn _ -> ()
        | _ -> Oth.Assert.false_ "Expected `Exn");
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0);
    Oth.test ~name:"Diamond dependency with shared child and exception" (fun _ ->
        (* Task graph:
                   parent
                  /      \_______
              child_a          child_b
               /   \            /   \
           child_c child_d child_c child_e
                       ^
                   (throws)

            child_c is called from both children
         *)
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let st = Bs.St.create (ref Hmap.empty) in
        let parent : int Hmap.key = Hmap.Key.create "parent" in
        let child_a : int Hmap.key = Hmap.Key.create "child_a" in
        let child_b : int Hmap.key = Hmap.Key.create "child_b" in
        let child_c : int Hmap.key = Hmap.Key.create "child_c" in
        let child_d : int Hmap.key = Hmap.Key.create "child_d" in
        let child_e : int Hmap.key = Hmap.Key.create "child_e" in
        (* Triggers and started promises for leaf tasks *)
        let child_c_started = Fut.Promise.create () in
        let child_c_trigger = Fut.Promise.create () in
        let child_d_started = Fut.Promise.create () in
        let child_d_trigger = Fut.Promise.create () in
        let child_e_started = Fut.Promise.create () in
        let child_e_trigger = Fut.Promise.create () in
        let parent_task =
         fun _ _ { Bs.Fetcher.fetch } ->
          let open Fut.Infix_monad in
          Fc.all2 (fetch child_a) (fetch child_b) >>= fun (a, b) -> Fut.return (a + b)
        in
        let child_a_task =
         fun _ _ { Bs.Fetcher.fetch } ->
          let open Fut.Infix_monad in
          Fc.all2 (fetch child_c) (fetch child_d) >>= fun (c, d) -> Fut.return (c + d)
        in
        let child_b_task =
         fun _ _ { Bs.Fetcher.fetch } ->
          let open Fut.Infix_monad in
          Fc.all2 (fetch child_c) (fetch child_e) >>= fun (c, e) -> Fut.return (c + e)
        in
        let child_c_task =
         fun _ _ _ ->
          let open Fut.Infix_monad in
          Fut.Promise.set child_c_started ()
          >>= fun () -> Fut.Promise.future child_c_trigger >>= fun () -> Fut.return 1
        in
        let child_d_task =
         fun _ _ _ ->
          let open Fut.Infix_monad in
          Fut.Promise.set child_d_started ()
          >>= fun () ->
          Fut.Promise.future child_d_trigger >>= fun () -> raise (Failure "child_d exception")
        in
        let child_e_task =
         fun _ _ _ ->
          let open Fut.Infix_monad in
          Fut.Promise.set child_e_started ()
          >>= fun () -> Fut.Promise.future child_e_trigger >>= fun () -> Fut.return 3
        in
        let tasks_map =
          Hmap.empty
          |> Hmap.add (coerce parent) parent_task
          |> Hmap.add (coerce child_a) child_a_task
          |> Hmap.add (coerce child_b) child_b_task
          |> Hmap.add (coerce child_c) child_c_task
          |> Hmap.add (coerce child_d) child_d_task
          |> Hmap.add (coerce child_e) child_e_task
        in
        let tasks =
          { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
        in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 () >>= fun queue -> Bs.build queue rebuilder tasks parent st
        in
        ignore (Fut.run_with_state run dummy_state);
        (* Verify all leaf tasks have started *)
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future child_c_started))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future child_d_started))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future child_e_started))
          (`Det ());
        (* Trigger child_d to throw exception *)
        ignore (Fut.run_with_state (Fut.Promise.set child_d_trigger ()) dummy_state);
        (* a. Verify build fails with Exn *)
        (match Fut.state run with
        | `Exn _ -> ()
        | `Undet -> Oth.Assert.false_ "Build should not be undetermined"
        | _ -> Oth.Assert.false_ "Expected `Exn");
        (* b. Verify running tasks and suspended tasks are 0 *)
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        (* c. Verify buildsys running and blocking counts are 0 *)
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.running_count st) 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int (Bs.St.blocking_count st) 0;
        (* d. Verify all children triggers are failed with aborted or Exn *)
        (match Fut.state (Fut.Promise.future child_c_trigger) with
        | `Aborted | `Exn _ -> ()
        | `Undet -> Oth.Assert.false_ "child_c_trigger should not be undetermined"
        | `Det _ -> Oth.Assert.false_ "child_c_trigger should not be determined");
        match Fut.state (Fut.Promise.future child_e_trigger) with
        | `Aborted | `Exn _ -> ()
        | `Undet -> Oth.Assert.false_ "child_e_trigger should not be undetermined"
        | `Det _ -> Oth.Assert.false_ "child_e_trigger should not be determined");
  ]

let () =
  Random.self_init ();
  Oth.(run (parallel tests))
