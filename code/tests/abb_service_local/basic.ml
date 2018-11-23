module Fut = Abb_fut

module Service = Abb_service_local.Make(Fut)
module Channel = Abb_channel.Make(Fut)
module Channel_c = Channel.Combinators

let dummy_state = Fut.State.create ()

let basic_run =
  Oth.test
    ~desc:"Starting the service and sending it a message"
    ~name:"Basic run"
    (fun _ ->
       let runs = ref 0 in
       let f _ = Fut.return (incr runs) in
       let fut =
         let open Fut.Infix_monad in
         Service.create (fun _ -> Channel_c.iter ~f)
         >>= fun s ->
         Channel.send s ()
       in
       ignore (Fut.run_with_state fut dummy_state);
       assert (!runs = 1);
       assert (Fut.state fut = `Det (`Ok ())))

let service_throws_exn =
  Oth.test
    ~desc:"A running resource throwing an exception cleans up"
    ~name:"Service Throws Exn"
    (fun _ ->
       let f _ = failwith "fail" in
       let fut =
         let open Fut.Infix_monad in
         Service.create (fun _ -> Channel_c.iter ~f)
         >>= fun s ->
         Channel.send s ()
         >>= fun _ ->
         Channel.close s
         >>= fun () ->
         Channel.send s ()
       in
       ignore (Fut.run_with_state fut dummy_state);
       assert (Fut.state fut = `Det `Closed))

let () =
  Random.self_init ();
  Oth.(
    run
      (parallel [ basic_run
                ; service_throws_exn
                ]))
