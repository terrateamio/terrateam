module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let test_applicative =
    Oth_abb.test ~desc:"Applicatives run concurrently" ~name:"Applicative Concurrent" (fun () ->
        let open Abb.Future.Infix_monad in
        let open Abb.Future.Infix_app in
        let start_time = Unix.time () in
        let fut1 = Abb.Sys.sleep 1.0 in
        let fut2 = Abb.Sys.sleep 1.0 in
        (fun () () -> ())
        <$> fut1
        <*> fut2
        >>| fun () ->
        let end_time = Unix.time () in
        assert (end_time -. start_time < 1.8))

  let test = Oth_abb.serial [ test_applicative ]
end
