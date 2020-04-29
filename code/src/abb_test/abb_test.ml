module Make =
functor
  (Abb : Abb_intf.S)
  ->
  struct
    open Abb.Future.Infix_monad
    module Oth_abb = Oth_abb.Make (Abb)
    module Thread = Abb_test_thread.Make (Abb)
    module Sleep = Abb_test_sleep.Make (Abb)
    module Simple = Abb_test_simple.Make (Abb)
    module Getaddrinfo = Abb_test_getaddrinfo.Make (Abb)
    module Socket = Abb_test_socket.Make (Abb)
    module Process = Abb_test_process.Make (Abb)

    let test =
      Oth_abb.to_sync_test
        (Oth_abb.serial
           [ Thread.test; Sleep.test; Simple.test; Getaddrinfo.test; Socket.test; Process.test ])

    let run_tests () =
      Random.self_init ();
      Oth.run test
  end
