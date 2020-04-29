type ('s, 'f) t = ((string, 's) Brtl_ctx.t, (string, 'f) Brtl_ctx.t) result

let run ~on_failure ~f ctx =
  let open Abb.Future.Infix_monad in
  f ctx
  >>| function
  | Ok ctx    -> ctx
  | Error ctx -> on_failure ctx

module Infix = struct
  let ( @--> ) f1 f2 v =
    let open Abb.Future.Infix_monad in
    f1 v
    >>= function
    | Ok ctx         -> f2 ctx
    | Error _ as err -> Abb.Future.return err
end
