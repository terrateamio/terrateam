module Make = functor (Abb : Abb_intf.S) -> struct
  module Oth_abb = Oth_abb.Make(Abb)

  let thread_run_test =
    Oth_abb.test
      ~desc:"Simple increment in thread"
      ~name:"Thread run"
      (fun () ->
         let open Abb.Future.Infix_monad in
         let n = Random.int 10 in
         Abb.Thread.run (fun () -> n + 1)
         >>| fun n' ->
         assert ((n + 1) = n'))

  let test =
    Oth_abb.serial
      [ thread_run_test ]
end
