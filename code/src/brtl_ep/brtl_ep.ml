type ('s, 'f) t = ((string, 's) Brtl_ctx.t, (string, 'f) Brtl_ctx.t) result

let on_failure ctx =
  match Brtl_ctx.response ctx with
  | `Forbidden -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx
  | `Location uri ->
      let headers = Cohttp.Header.of_list [ ("location", Uri.to_string uri) ] in
      Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`See_other "") ctx

let run ~on_failure ~f ctx =
  let open Abb.Future.Infix_monad in
  f ctx
  >>| function
  | Ok ctx -> ctx
  | Error ctx -> on_failure ctx

let run_result ~f (ctx : (string, 'a) Brtl_ctx.t) =
  let open Abb.Future.Infix_monad in
  f ctx
  >>| function
  | Ok ctx -> ctx
  | Error ctx -> on_failure ctx

module Infix = struct
  let ( @--> ) f1 f2 v =
    let open Abb.Future.Infix_monad in
    f1 v
    >>= function
    | Ok ctx -> f2 ctx
    | Error _ as err -> Abb.Future.return err
end
