module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let process_done () = function
    | Ok code -> Abb.Future.return ()
    | Error _ -> failwith "process failed to finish"

  let process_test =
    Oth_abb.test ~desc:"Run the true program" ~name:"Process test" (fun () ->
        (* let open Abb.Future.Infix_monad in *)
        (* let init_args = Abb_intf.Process.{ exec_name = "true"; args = []; env = None } in *)
        (* match *)
        (*   Abb.Process.spawn ~stdin:Unix.stdin ~stdout:Unix.stdout ~stderr:Unix.stderr init_args *)
        (* with *)
        (* | Ok t -> Abb.Process.wait t >>= fun _ -> Abb.Future.return () *)
        (* | Error _ -> failwith "process error" *)
        Abb.Future.return ())

  let test = Oth_abb.serial [ process_test ]
end
