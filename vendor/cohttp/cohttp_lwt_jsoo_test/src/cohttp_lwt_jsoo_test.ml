module Client = Cohttp_lwt_jsoo.Client
module Js = Js_of_ocaml.Js

let _Promise = Js.Unsafe.global##._Promise
let ( let* ) = Lwt.( >>= )
let ( let+ ) = Lwt.( >|= )

let promise_of_lwt lwt =
  new%js _Promise
    (Js.wrap_callback (fun resolve reject ->
         try%lwt
           let+ res = lwt () in
           Js.Unsafe.fun_call resolve [| Js.Unsafe.inject res |]
         with e ->
           let msg = Printexc.to_string e in
           Js.Unsafe.fun_call reject
             [| Js.Unsafe.inject (new%js Js.error_constr (Js.string msg)) |]))

let () =
  Js.export_all
    (object%js
       method request uri =
         let f () =
           let uri = Uri.of_string (Js.to_string uri) in
           let* response, body = Client.get uri in
           let+ body = Cohttp_lwt.Body.to_string body in
           let status =
             Cohttp.Response.status response |> Cohttp.Code.code_of_status
           in
           Js.array
             [| Js.Unsafe.inject status; Js.Unsafe.inject @@ Js.string body |]
         in
         promise_of_lwt f
    end)
