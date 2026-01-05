let run' msg f =
  let open Abb.Future.Infix_monad in
  Abb.Sys.monotonic ()
  >>= fun start ->
  f ()
  >>= fun ret ->
  Abb.Sys.monotonic ()
  >>= fun stop ->
  msg ret (stop -. start);
  Abb.Future.return ret

let run msg f = run' (fun _ -> msg) f
