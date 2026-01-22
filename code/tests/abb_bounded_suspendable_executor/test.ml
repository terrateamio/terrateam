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

let tests =
  [
    Oth.test ~name:"Simple" (fun _ ->
        let trigger = Fut.Promise.create () in
        let finished = Fut.Promise.create () in
        let run =
          let open Fut.Infix_monad in
          Exec.create ~slots:10 ()
          >>= fun executor ->
          Exec.run executor ~name:[ "test" ] (fun () ->
              Fut.Promise.future trigger >>= fun () -> Fut.Promise.set finished ())
        in
        ignore (Fut.run_with_state run dummy_state);
        assert (Fut.state (Fut.Promise.future finished) = `Undet);
        ignore (Fut.run_with_state (Fut.Promise.set trigger ()) dummy_state);
        assert (Fut.state (Fut.Promise.future finished) = `Det ());
        assert (Fut.state run = `Det ()));
  ]

let () =
  Random.self_init ();
  Oth.(run (parallel tests))
