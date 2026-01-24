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

let tests =
  [
    Oth.test ~name:"Simple" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let finished = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () ->
              Fut.Promise.future trigger >>= fun () -> Fut.Promise.set finished ())
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished))
          (`Det ());
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Task throws exn" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () -> failwith "test exception")
        in
        ignore (Fut.run_with_state run dummy_state);
        (match Fut.state run with
        | `Exn _ -> ()
        | _ -> Oth.Assert.false_ "Expected `Exn");
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Task throws exn after wait" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () ->
              Fut.Promise.future trigger >>= fun () -> failwith "test exception")
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
        (match Fut.state run with
        | `Exn _ -> ()
        | _ -> Oth.Assert.false_ "Expected `Exn");
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Aborts handled correctly" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let work_started = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () ->
              Fut.Promise.set work_started () >>= fun () -> Fut.Promise.future trigger)
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future work_started))
          (`Det ());
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) `Undet;
        ignore (Fut.run_with_state (Fut.abort run) dummy_state);
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) `Aborted;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future trigger))
          `Aborted;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Aborting the running task" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let work_started = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () ->
              Fut.Promise.set work_started () >>= fun () -> Fut.Promise.future trigger)
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future work_started))
          (`Det ());
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) `Undet;
        ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future trigger)) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future trigger))
          `Aborted;
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state run) `Aborted;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Suspend/unsuspend" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger1 = Fut.Promise.create () in
        let trigger2 = Fut.Promise.create () in
        let suspend_trigger = Fut.Promise.create () in
        let unsuspend_trigger = Fut.Promise.create () in
        let finished1 = Fut.Promise.create () in
        let finished2 = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "task1" ] (fun () ->
                 Fut.Promise.future trigger1 >>= fun () -> Fut.Promise.set finished1 ()))
          >>= fun _ ->
          Fut.Promise.future suspend_trigger
          >>= fun () ->
          Exec.suspend ~name:[ "task1" ] executor
          >>= fun () ->
          Fut.fork
            (Exec.run executor ~name:[ "task2" ] (fun () ->
                 Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set finished2 ()))
          >>= fun _ ->
          Fut.Promise.future unsuspend_trigger
          >>= fun () -> Exec.unsuspend ~name:[ "task1" ] executor
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished1))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set suspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished2))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set unsuspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished1))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Slots limit respected" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger1 = Fut.Promise.create () in
        let trigger2 = Fut.Promise.create () in
        let trigger3 = Fut.Promise.create () in
        let trigger4 = Fut.Promise.create () in
        let trigger5 = Fut.Promise.create () in
        let finished1 = Fut.Promise.create () in
        let finished2 = Fut.Promise.create () in
        let finished3 = Fut.Promise.create () in
        let finished4 = Fut.Promise.create () in
        let finished5 = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:1 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "task1" ] (fun () ->
                 Fut.Promise.future trigger1 >>= fun () -> Fut.Promise.set finished1 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task2" ] (fun () ->
                 Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set finished2 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task3" ] (fun () ->
                 Fut.Promise.future trigger3 >>= fun () -> Fut.Promise.set finished3 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task4" ] (fun () ->
                 Fut.Promise.future trigger4 >>= fun () -> Fut.Promise.set finished4 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task5" ] (fun () ->
                 Fut.Promise.future trigger5 >>= fun () -> Fut.Promise.set finished5 ()))
          >>= fun _ -> Fut.return ()
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished1))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished1))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished2))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger3 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished3))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger4 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished4))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger5 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished5))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Slots limit respected with suspend" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger1 = Fut.Promise.create () in
        let trigger2 = Fut.Promise.create () in
        let trigger3 = Fut.Promise.create () in
        let trigger4 = Fut.Promise.create () in
        let trigger5 = Fut.Promise.create () in
        let finished1 = Fut.Promise.create () in
        let finished2 = Fut.Promise.create () in
        let finished3 = Fut.Promise.create () in
        let finished4 = Fut.Promise.create () in
        let finished5 = Fut.Promise.create () in
        let started1 = Fut.Promise.create () in
        let started2 = Fut.Promise.create () in
        let started3 = Fut.Promise.create () in
        let started4 = Fut.Promise.create () in
        let started5 = Fut.Promise.create () in
        let suspend1 = Fut.Promise.create () in
        let suspend2 = Fut.Promise.create () in
        let suspend3 = Fut.Promise.create () in
        let suspend4 = Fut.Promise.create () in
        let suspend5 = Fut.Promise.create () in
        let unsuspend_trigger = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:1 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "task1" ] (fun () ->
                 Fut.Promise.set started1 ()
                 >>= fun () ->
                 Fut.Promise.future trigger1 >>= fun () -> Fut.Promise.set finished1 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task2" ] (fun () ->
                 Fut.Promise.set started2 ()
                 >>= fun () ->
                 Fut.Promise.future trigger2 >>= fun () -> Fut.Promise.set finished2 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task3" ] (fun () ->
                 Fut.Promise.set started3 ()
                 >>= fun () ->
                 Fut.Promise.future trigger3 >>= fun () -> Fut.Promise.set finished3 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task4" ] (fun () ->
                 Fut.Promise.set started4 ()
                 >>= fun () ->
                 Fut.Promise.future trigger4 >>= fun () -> Fut.Promise.set finished4 ()))
          >>= fun _ ->
          Fut.fork
            (Exec.run executor ~name:[ "task5" ] (fun () ->
                 Fut.Promise.set started5 ()
                 >>= fun () ->
                 Fut.Promise.future trigger5 >>= fun () -> Fut.Promise.set finished5 ()))
          >>= fun _ ->
          Fut.Promise.future suspend1
          >>= fun () ->
          Exec.suspend ~name:[ "task1" ] executor
          >>= fun () ->
          Fut.Promise.future suspend2
          >>= fun () ->
          Exec.suspend ~name:[ "task2" ] executor
          >>= fun () ->
          Fut.Promise.future suspend3
          >>= fun () ->
          Exec.suspend ~name:[ "task3" ] executor
          >>= fun () ->
          Fut.Promise.future suspend4
          >>= fun () ->
          Exec.suspend ~name:[ "task4" ] executor
          >>= fun () ->
          Fut.Promise.future suspend5
          >>= fun () ->
          Exec.suspend ~name:[ "task5" ] executor
          >>= fun () ->
          Fut.Promise.future unsuspend_trigger
          >>= fun () ->
          Exec.unsuspend ~name:[ "task1" ] executor
          >>= fun () ->
          Exec.unsuspend ~name:[ "task2" ] executor
          >>= fun () ->
          Exec.unsuspend ~name:[ "task3" ] executor
          >>= fun () ->
          Exec.unsuspend ~name:[ "task4" ] executor
          >>= fun () -> Exec.unsuspend ~name:[ "task5" ] executor
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started1))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started2))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set suspend1 ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 1;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started2))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started3))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set suspend2 ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 2;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started3))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started4))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set suspend3 ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 3;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started4))
          (`Det ());
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started5))
          `Undet;
        ignore (Fut.run_with_state (Fut.Promise.set suspend4 ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 1;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 4;
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future started5))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set suspend5 ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 5;
        ignore (Fut.run_with_state (Fut.Promise.set unsuspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0;
        ignore (Fut.run_with_state (Fut.Promise.set trigger1 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished1))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set trigger2 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished2))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set trigger3 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished3))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set trigger4 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished4))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set trigger5 ()) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future finished5))
          (`Det ());
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Task throws exn while suspended" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let suspend_trigger = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "test" ] (fun () ->
                 Fut.Promise.future trigger >>= fun () -> failwith "test exception"))
          >>= fun task ->
          Fut.Promise.future suspend_trigger
          >>= fun () -> Exec.suspend ~name:[ "test" ] executor >>= fun () -> Fut.return task
        in
        ignore (Fut.run_with_state run dummy_state);
        ignore (Fut.run_with_state (Fut.Promise.set suspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 1;
        ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Aborts handled correctly while suspended" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let work_started = Fut.Promise.create () in
        let suspend_trigger = Fut.Promise.create () in
        let task_ref = ref None in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "test" ] (fun () ->
                 Fut.Promise.set work_started () >>= fun () -> Fut.Promise.future trigger))
          >>= fun task ->
          task_ref := Some task;
          Fut.Promise.future suspend_trigger
          >>= fun () -> Exec.suspend ~name:[ "test" ] executor >>= fun () -> Fut.return task
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future work_started))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set suspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 1;
        let task = Option.get !task_ref in
        ignore (Fut.run_with_state (Fut.abort task) dummy_state);
        Oth.Assert.eq ~eq:Pp_unit.equal ~pp:Pp_unit.pp (Fut.state task) `Aborted;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
    Oth.test ~name:"Aborting the running task while suspended" (fun _ ->
        let logger, running_tasks_count, suspended_tasks_count = make_logger () in
        let trigger = Fut.Promise.create () in
        let work_started = Fut.Promise.create () in
        let suspend_trigger = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~logger ~slots:10 ()
          >>= fun executor ->
          Fut.fork
            (Exec.run executor ~name:[ "test" ] (fun () ->
                 Fut.Promise.set work_started () >>= fun () -> Fut.Promise.future trigger))
          >>= fun task ->
          Fut.Promise.future suspend_trigger
          >>= fun () -> Exec.suspend ~name:[ "test" ] executor >>= fun () -> Fut.return task
        in
        ignore (Fut.run_with_state run dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future work_started))
          (`Det ());
        ignore (Fut.run_with_state (Fut.Promise.set suspend_trigger ()) dummy_state);
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 1;
        ignore (Fut.run_with_state (Fut.abort (Fut.Promise.future trigger)) dummy_state);
        Oth.Assert.eq
          ~eq:Pp_unit.equal
          ~pp:Pp_unit.pp
          (Fut.state (Fut.Promise.future trigger))
          `Aborted;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !running_tasks_count 0;
        Oth.Assert.eq ~eq:Int.equal ~pp:Format.pp_print_int !suspended_tasks_count 0);
  ]

let () =
  Random.self_init ();
  Oth.(run (parallel tests))
