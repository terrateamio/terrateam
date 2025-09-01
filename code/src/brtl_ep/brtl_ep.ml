type ('s, 'f) t = ((string, 's) Brtl_ctx.t, (string, 'f) Brtl_ctx.t) result

let on_failure ctx =
  match Brtl_ctx.response ctx with
  | `Forbidden -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx
  | `Internal_server_error ->
      Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx
  | `Location uri ->
      let headers = Cohttp.Header.of_list [ ("location", Uri.to_string uri) ] in
      Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`See_other "") ctx

let set_content_type content_type ctx =
  let rspnc =
    Brtl_rspnc.add_header_if_not_exists "content-type" content_type @@ Brtl_ctx.response ctx
  in
  Brtl_ctx.set_response rspnc ctx

let run ~content_type ~f ctx =
  let open Abb.Future.Infix_monad in
  f ctx >>= fun ctx -> Abb.Future.return @@ set_content_type content_type ctx

let run_json ~f ctx = run ~content_type:"application/json" ~f ctx

let run_result ~content_type ~f (ctx : (string, 'a) Brtl_ctx.t) =
  let open Abb.Future.Infix_monad in
  f ctx
  >>| function
  | Ok ctx -> set_content_type content_type ctx
  | Error ctx -> on_failure ctx

let run_result_json ~f ctx = run_result ~content_type:"application/json" ~f ctx

module Infix = struct
  let ( @--> ) f1 f2 v =
    let open Abb.Future.Infix_monad in
    f1 v
    >>= function
    | Ok ctx -> f2 ctx
    | Error _ as err -> Abb.Future.return err
end
