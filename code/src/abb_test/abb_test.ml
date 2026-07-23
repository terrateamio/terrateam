module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)
  module Concurrency = Abb_test_concurrency.Make (Abb)
  module Thread = Abb_test_thread.Make (Abb)
  module Sleep = Abb_test_sleep.Make (Abb)
  module Simple = Abb_test_simple.Make (Abb)
  module Getaddrinfo = Abb_test_getaddrinfo.Make (Abb)
  module Socket = Abb_test_socket.Make (Abb)
  module Socket_closed = Abb_test_socket_closed.Make (Abb)
  module Process = Abb_test_process.Make (Abb)
  module Task = Abb_test_task.Make (Abb)
  module Op_queue = Abb_test_op_queue.Make (Abb)
  module Chan = Abb_test_chan.Make (Abb)
  module Unpinned = Abb_test_unpinned.Make (Abb)
  module Unpinned_chan = Abb_test_unpinned_chan.Make (Abb)
  module Unpinned_send = Abb_test_unpinned_send.Make (Abb)
  module Unpinned_stress = Abb_test_unpinned_stress.Make (Abb)
  module Pool_pressure = Abb_test_pool_pressure.Make (Abb)
  module Domain = Abb_test_domain.Make (Abb)

  let test =
    Oth_abb.to_sync_test
      (Oth_abb.serial
         [
           Concurrency.test;
           Thread.test;
           Sleep.test;
           Simple.test;
           Getaddrinfo.test;
           Socket.test;
           Socket_closed.test;
           Process.test;
           Task.test;
           Op_queue.test;
           Chan.test;
           Unpinned.test;
           Unpinned_chan.test;
           Unpinned_send.test;
           Unpinned_stress.test;
           Pool_pressure.test;
           Domain.test;
         ])

  let run_tests () =
    Random.self_init ();
    Oth.run ~file:__FILE__ test
end
