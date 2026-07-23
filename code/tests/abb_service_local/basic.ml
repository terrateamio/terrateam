module Service = Abb_service_local.Make (Abb)

let basic_run =
  Oth.test ~desc:"Starting the service and sending it a message" ~name:"Basic run" (fun _ ->
      let runs = ref 0 in
      let body chan =
        let open Abb.Future.Infix_monad in
        Abb.Chan.recv chan
        >>= function
        | Ok () ->
            incr runs;
            Abb.Future.return ()
        | Error `Chan_closed -> Abb.Future.return ()
      in
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create body
        >>= fun s ->
        Abb.Chan.send s () >>= fun _ -> Abb.Sys.sleep 0.01 >>= fun () -> Abb.Future.return ()
      in
      ignore (Abb.Scheduler.run_with_state (fun _ -> fut));
      Oth.Assert.eq ~eq:CCInt.equal ~pp:Format.pp_print_int 1 !runs)

let service_throws_exn =
  Oth.test
    ~desc:"A running resource throwing an exception cleans up"
    ~name:"Service Throws Exn"
    (fun _ ->
      let body _chan = failwith "fail" in
      let fut =
        let open Abb.Future.Infix_monad in
        Service.create body
        >>= fun s ->
        Abb.Sys.sleep 0.01
        >>= fun () ->
        Abb.Chan.send s ()
        >>= function
        | Ok () -> Abb.Future.return `Ok
        | Error `Chan_closed -> Abb.Future.return `Closed
      in
      let r = Abb.Scheduler.run_with_state (fun _ -> fut) in
      match r with
      | `Det `Closed -> ()
      | _ -> Oth.Assert.false_ "expected `Det `Closed")

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ (Oth.parallel [ basic_run; service_throws_exn ])
