module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let root_is_zero =
    Oth_abb.test
      ~desc:"Root chain (no Task.run) reads task_id = 0 and task_name = None"
      ~name:"Task root zero"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.id ()
        >>= fun id ->
        Oth.Assert.Eq.int ~expected:0 ~actual:id;
        Abb.Task.name ()
        >>= fun n ->
        Oth.Assert.Eq.string_option ~expected:None ~actual:n;
        Abb.Future.return ())

  (* Discarding the future returned by [Task.run] (without awaiting the inner
     task's completion via [task >>= …]) must still leave the outer chain's
     id intact.  Exercises the [bind] on [Task.run]'s [with_state] output —
     a different path than [task >>= …] which binds on the fork's inner. *)
  let outer_id_intact_when_task_future_discarded =
    Oth_abb.test
      ~desc:"after [Task.run () >>= fun _ -> ...], Task.id reads the outer id"
      ~name:"Task discarded future"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.id ()
        >>= fun outer ->
        Abb.Task.run (fun () ->
            Abb.Task.id ()
            >>= fun inner ->
            Oth.Assert.true_ "inner task id differs from outer" (inner <> outer);
            Abb.Future.return ())
        >>= fun _task ->
        Abb.Task.id ()
        >>= fun outer' ->
        Oth.Assert.Eq.int ~expected:outer ~actual:outer';
        Abb.Future.return ())

  let nested_id =
    Oth_abb.test
      ~desc:"Task.run yields a fresh id; outer id is restored after task completes"
      ~name:"Task nested id"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.id ()
        >>= fun outer ->
        Oth.Assert.Eq.int ~expected:0 ~actual:outer;
        Abb.Task.run (fun () ->
            Abb.Task.id ()
            >>= fun inner ->
            Oth.Assert.true_ "inner task id differs from outer" (outer <> inner);
            Abb.Future.return ())
        >>= fun task ->
        task
        >>= fun () ->
        Abb.Task.id ()
        >>= fun outer' ->
        Oth.Assert.Eq.int ~expected:outer ~actual:outer';
        Abb.Future.return ())

  let name_propagates =
    Oth_abb.test
      ~desc:"Task.name returns the name passed to Task.run inside, None outside"
      ~name:"Task name"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.name ()
        >>= fun outer_name ->
        Oth.Assert.Eq.string_option ~expected:None ~actual:outer_name;
        Abb.Task.run ~name:"worker" (fun () ->
            Abb.Task.name ()
            >>= fun n ->
            Oth.Assert.Eq.string_option ~expected:(Some "worker") ~actual:n;
            Abb.Future.return ())
        >>= fun task -> task)

  let sibling_isolation =
    Oth_abb.test
      ~desc:"two sibling Task.run chains see distinct ids"
      ~name:"Task sibling isolation"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run (fun () -> Abb.Task.id ())
        >>= fun a ->
        Abb.Task.run (fun () -> Abb.Task.id ())
        >>= fun b ->
        a
        >>= fun ia ->
        b
        >>= fun ib ->
        Oth.Assert.true_ "sibling task ids differ" (ia <> ib);
        Abb.Future.return ())

  (* Three nesting levels.  Each level captures its own id, dives into the next, and
     after the inner returns must read the same id it captured before the dive. *)
  let deep_nesting =
    Oth_abb.test
      ~desc:"Task.run can nest 3+ deep; each level's id is restored on return"
      ~name:"Task deep nesting"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run ~name:"outer" (fun () ->
            Abb.Task.id ()
            >>= fun outer ->
            Abb.Task.run ~name:"middle" (fun () ->
                Abb.Task.id ()
                >>= fun middle ->
                Oth.Assert.true_ "middle task id differs from outer" (middle <> outer);
                Abb.Task.run ~name:"inner" (fun () ->
                    Abb.Task.id ()
                    >>= fun inner ->
                    Oth.Assert.true_ "inner task id differs from middle" (inner <> middle);
                    Oth.Assert.true_ "inner task id differs from outer" (inner <> outer);
                    Abb.Future.return ())
                >>= fun task ->
                task
                >>= fun () ->
                Abb.Task.id ()
                >>= fun middle' ->
                Oth.Assert.Eq.int ~expected:middle ~actual:middle';
                Abb.Future.return ())
            >>= fun task ->
            task
            >>= fun () ->
            Abb.Task.id ()
            >>= fun outer' ->
            Oth.Assert.Eq.int ~expected:outer ~actual:outer';
            Abb.Future.return ())
        >>= fun task -> task)

  (* Outer awaits a promise that an inner Task.run sets.  When the promise resolves,
     the outer continuation must see the OUTER id, not the inner setter's id. *)
  let promise_does_not_leak_inner_id =
    Oth_abb.test
      ~desc:"a promise set inside Task.run does not propagate the inner id to the awaiter"
      ~name:"Task promise no-leak"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let p = Abb.Future.Promise.create () in
        Abb.Task.id ()
        >>= fun outer ->
        Abb.Task.run ~name:"setter" (fun () ->
            Abb.Task.id ()
            >>= fun inner ->
            Oth.Assert.true_ "inner task id differs from outer" (inner <> outer);
            Abb.Future.Promise.set p inner)
        >>= fun task ->
        Abb.Future.Promise.future p
        >>= fun inner_id ->
        Abb.Task.id ()
        >>= fun outer_after_promise ->
        Oth.Assert.Eq.int ~expected:outer ~actual:outer_after_promise;
        Oth.Assert.true_ "promised inner id differs from outer" (inner_id <> outer);
        task)

  (* Many sequential binds inside one task.  No drift — every step reads the same id. *)
  let long_bind_chain_inside_task =
    Oth_abb.test
      ~desc:"a long bind chain inside Task.run sees the same id at every step"
      ~name:"Task long chain"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run (fun () ->
            Abb.Task.id ()
            >>= fun id ->
            let rec loop n =
              if n = 0 then Abb.Future.return ()
              else
                Abb.Task.id ()
                >>= fun id' ->
                Oth.Assert.Eq.int ~expected:id ~actual:id';
                loop (n - 1)
            in
            loop 50)
        >>= fun task -> task)

  (* Sleep crosses an event-loop turn.  The id captured before the sleep must still
     be the value [Task.id] reads on the other side. *)
  let task_id_survives_sleep =
    Oth_abb.test
      ~desc:"Task.id is preserved across an event-loop sleep inside a task"
      ~name:"Task id survives sleep"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run (fun () ->
            Abb.Task.id ()
            >>= fun before ->
            Abb.Sys.sleep 0.05
            >>= fun () ->
            Abb.Task.id ()
            >>= fun after ->
            Oth.Assert.Eq.int ~expected:before ~actual:after;
            Abb.Future.return ())
        >>= fun task -> task)

  (* Two tasks composed via the applicative.  Each side records its own id; after the
     join we re-check the outer id is intact. *)
  let applicative_parallel_tasks =
    Oth_abb.test
      ~desc:"applicative <*> over two Task.run chains: each sees its own id; outer survives"
      ~name:"Task applicative parallel"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let open Abb.Future.Infix_app in
        Abb.Task.id ()
        >>= fun outer ->
        let task_a =
          Abb.Task.run (fun () ->
              Abb.Task.id ()
              >>= fun id_a ->
              Abb.Sys.sleep 0.02
              >>= fun () ->
              Abb.Task.id ()
              >>= fun id_a' ->
              Oth.Assert.Eq.int ~expected:id_a ~actual:id_a';
              Abb.Future.return id_a)
        in
        let task_b =
          Abb.Task.run (fun () ->
              Abb.Task.id ()
              >>= fun id_b ->
              Abb.Sys.sleep 0.01
              >>= fun () ->
              Abb.Task.id ()
              >>= fun id_b' ->
              Oth.Assert.Eq.int ~expected:id_b ~actual:id_b';
              Abb.Future.return id_b)
        in
        (fun a b -> (a, b))
        <$> task_a
        <*> task_b
        >>= fun (a, b) ->
        a
        >>= fun ia ->
        b
        >>= fun ib ->
        Oth.Assert.true_ "applicative task ids differ" (ia <> ib);
        Abb.Task.id ()
        >>= fun outer_after ->
        Oth.Assert.Eq.int ~expected:outer ~actual:outer_after;
        Abb.Future.return ())

  (* Id and name come from the same chain-data record.  If a watcher were partially
     installing fields from different sources, this would flag it. *)
  let id_and_name_coherent =
    Oth_abb.test
      ~desc:"inside Task.run, Task.id and Task.name come from the same chain-data record"
      ~name:"Task id/name coherent"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run ~name:"alpha" (fun () ->
            Abb.Task.id ()
            >>= fun id_a ->
            Abb.Task.name ()
            >>= fun n_a ->
            Oth.Assert.Eq.string_option ~expected:(Some "alpha") ~actual:n_a;
            Abb.Task.run ~name:"beta" (fun () ->
                Abb.Task.id ()
                >>= fun id_b ->
                Abb.Task.name ()
                >>= fun n_b ->
                Oth.Assert.Eq.string_option ~expected:(Some "beta") ~actual:n_b;
                Oth.Assert.true_ "nested task ids differ" (id_b <> id_a);
                Abb.Future.return ())
            >>= fun task ->
            task
            >>= fun () ->
            Abb.Task.id ()
            >>= fun id_a' ->
            Abb.Task.name ()
            >>= fun n_a' ->
            Oth.Assert.Eq.int ~expected:id_a ~actual:id_a';
            Oth.Assert.Eq.string_option ~expected:(Some "alpha") ~actual:n_a';
            Abb.Future.return ())
        >>= fun task -> task)

  (* Outer task launches several inner tasks sequentially, awaiting each.  Between
     each completion, the outer's id must still be there. *)
  let outer_id_stable_across_inner_tasks =
    Oth_abb.test
      ~desc:"outer id is unchanged after each of N sequential inner Task.run completions"
      ~name:"Task outer stable"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run ~name:"outer" (fun () ->
            Abb.Task.id ()
            >>= fun outer ->
            let rec spawn n =
              if n = 0 then Abb.Future.return ()
              else
                Abb.Task.run (fun () -> Abb.Task.id ())
                >>= fun task ->
                task
                >>= fun inner ->
                Oth.Assert.true_ "inner task id differs from outer" (inner <> outer);
                Abb.Task.id ()
                >>= fun outer' ->
                Oth.Assert.Eq.int ~expected:outer ~actual:outer';
                spawn (n - 1)
            in
            spawn 10)
        >>= fun task -> task)

  (* When a task is aborted, the abort handler attached to a [Promise.create ~abort]
     inside that task should run in the aborted task's chain context — so [Task.id]
     and [Task.name] inside the handler return the aborted task's values, regardless
     of who called [abort]. *)
  let abort_handler_sees_aborted_task_id =
    Oth_abb.test
      ~desc:"abort handler reads the aborted task's id and name (not the aborter's)"
      ~name:"Task abort sees aborted id"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let recorded_id = ref None in
        let recorded_name = ref None in
        let inner_id_capture = ref None in
        Abb.Task.run ~name:"child" (fun () ->
            Abb.Task.id ()
            >>= fun id ->
            inner_id_capture := Some id;
            let p =
              Abb.Future.Promise.create
                ~abort:(fun () ->
                  Abb.Task.id ()
                  >>= fun id' ->
                  recorded_id := Some id';
                  Abb.Task.name ()
                  >>= fun n ->
                  recorded_name := Some n;
                  Abb.Future.return ())
                ()
            in
            Abb.Future.Promise.future p)
        >>= fun task ->
        Abb.Future.abort task
        >>= fun () ->
        Oth.Assert.Eq.option
          ~eq:CCInt.equal
          ~pp:Format.pp_print_int
          ~expected:!inner_id_capture
          ~actual:!recorded_id;
        Oth.Assert.true_
          "abort handler saw the child task name"
          (!recorded_name = Some (Some "child"));
        Abb.Future.return ())

  (* Outer task aborts inner task; the handler running inside the inner should still
     see the inner's id, not the outer's. *)
  let abort_handler_id_differs_from_aborter =
    Oth_abb.test
      ~desc:"abort handler sees the aborted task's id, not the aborting task's id"
      ~name:"Task abort id is aborted's not aborter's"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let recorded_id = ref None in
        let aborter_id_capture = ref None in
        let aborted_id_capture = ref None in
        Abb.Task.run ~name:"aborter" (fun () ->
            Abb.Task.id ()
            >>= fun aid ->
            aborter_id_capture := Some aid;
            Abb.Task.run ~name:"victim" (fun () ->
                Abb.Task.id ()
                >>= fun vid ->
                aborted_id_capture := Some vid;
                let p =
                  Abb.Future.Promise.create
                    ~abort:(fun () ->
                      Abb.Task.id ()
                      >>= fun id ->
                      recorded_id := Some id;
                      Abb.Future.return ())
                    ()
                in
                Abb.Future.Promise.future p)
            >>= fun victim -> Abb.Future.abort victim)
        >>= fun task ->
        task
        >>= fun () ->
        Oth.Assert.Eq.option
          ~eq:CCInt.equal
          ~pp:Format.pp_print_int
          ~expected:!aborted_id_capture
          ~actual:!recorded_id;
        Oth.Assert.true_
          "abort handler id is the victim's, not the aborter's"
          (!recorded_id <> !aborter_id_capture);
        Abb.Future.return ())

  exception Boom

  (* Task body raises.  The awaiter awaits the task future and observes
     [`Exn] just like for any other failed future — Task.run adds no
     custom exception handling. *)
  let exn_propagates_to_awaiter =
    Oth_abb.test
      ~desc:"a raise inside Task.run propagates as `Exn to the awaiter"
      ~name:"Task exn propagates"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run (fun () -> raise Boom)
        >>= fun task ->
        Abb.Future.await task
        >>= fun result ->
        (match result with
        | `Exn (Boom, _) -> ()
        | `Exn _ -> Oth.Assert.false_ "task raised an unexpected exception; expected Boom"
        | `Det _ -> Oth.Assert.false_ "task completed; expected it to raise Boom"
        | `Aborted -> Oth.Assert.false_ "task aborted; expected it to raise Boom");
        Abb.Future.return ())

  (* After a task fails, code that resumes in the outer chain (via [await])
     reads the OUTER task id, not the failed inner task's.  The `Exn state
     carries no chain data; the awaiter's bind restores its own captured
     data. *)
  let outer_id_intact_after_task_exn =
    Oth_abb.test
      ~desc:"after a task raises, Task.id in the awaiting chain reads the outer id"
      ~name:"Task exn outer id intact"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.id ()
        >>= fun outer ->
        Abb.Task.run (fun () ->
            Abb.Task.id ()
            >>= fun inner ->
            Oth.Assert.true_ "inner task id differs from outer" (inner <> outer);
            raise Boom)
        >>= fun task ->
        Abb.Future.await task
        >>= fun _ ->
        Abb.Task.id ()
        >>= fun after ->
        Oth.Assert.Eq.int ~expected:outer ~actual:after;
        Abb.Future.return ())

  (* An aborted task surfaces as [`Aborted] to the awaiter; outer chain
     data is preserved (mirror of the [`Exn] case). *)
  let outer_id_intact_after_task_abort =
    Oth_abb.test
      ~desc:"after a task is aborted, Task.id in the awaiting chain reads the outer id"
      ~name:"Task abort outer id intact"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.id ()
        >>= fun outer ->
        Abb.Task.run (fun () ->
            let p = Abb.Future.Promise.create () in
            Abb.Future.Promise.future p)
        >>= fun task ->
        Abb.Future.abort task
        >>= fun () ->
        Abb.Future.await task
        >>= fun result ->
        (match result with
        | `Aborted -> ()
        | `Det _ | `Exn _ -> Oth.Assert.false_ "expected an aborted task, got Det/Exn");
        Abb.Task.id ()
        >>= fun after ->
        Oth.Assert.Eq.int ~expected:outer ~actual:after;
        Abb.Future.return ())

  (* If the abort callback itself raises, [safe_call_abort] catches the
     exception and treats the abort as if it succeeded (returning a
     [`Aborted] future).  The awaiter therefore sees [`Aborted] — the
     exception does NOT surface up.  This is the existing engine
     behaviour; this test pins it. *)
  let abort_handler_exn_swallowed =
    Oth_abb.test
      ~desc:"an exception raised by an abort callback is swallowed; awaiter sees `Aborted"
      ~name:"Task abort handler raises"
      (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Task.run (fun () ->
            let p = Abb.Future.Promise.create ~abort:(fun () -> raise Boom) () in
            Abb.Future.Promise.future p)
        >>= fun task ->
        Abb.Future.abort task
        >>= fun () ->
        Abb.Future.await task
        >>= fun result ->
        (match result with
        | `Aborted -> ()
        | `Det _ | `Exn _ -> Oth.Assert.false_ "expected an aborted task, got Det/Exn");
        Abb.Future.return ())

  let test =
    Oth_abb.serial
      [
        root_is_zero;
        outer_id_intact_when_task_future_discarded;
        nested_id;
        name_propagates;
        sibling_isolation;
        deep_nesting;
        promise_does_not_leak_inner_id;
        long_bind_chain_inside_task;
        task_id_survives_sleep;
        applicative_parallel_tasks;
        id_and_name_coherent;
        outer_id_stable_across_inner_tasks;
        abort_handler_sees_aborted_task_id;
        abort_handler_id_differs_from_aborter;
        exn_propagates_to_awaiter;
        outer_id_intact_after_task_exn;
        outer_id_intact_after_task_abort;
        abort_handler_exn_swallowed;
      ]
end
