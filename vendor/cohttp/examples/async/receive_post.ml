(* This file is in the public domain *)
open Base
open Async_kernel
open Cohttp_async

(* compile with: $ corebuild receive_post.native -pkg cohttp.async *)

let start_server port () =
  Stdlib.Printf.eprintf "Listening for HTTP on port %d\n" port;
  Stdlib.Printf.eprintf "Try 'curl -X POST -d 'foo bar' http://localhost:%d\n"
    port;
  Cohttp_async.Server.create ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port) (fun ~body _ req ->
      match req |> Cohttp.Request.meth with
      | `POST ->
          Body.to_string body >>= fun body ->
          Stdlib.Printf.eprintf "Body: %s" body;
          Server.respond `OK
      | _ -> Server.respond `Method_not_allowed)
  >>= fun _ -> Deferred.never ()

let () =
  let module Command = Async_command in
  Command.async_spec ~summary:"Simple http server that outputs body of POST's"
    Command.Spec.(
      empty
      +> flag "-p"
           (optional_with_default 8080 int)
           ~doc:"int Source port to listen on")
    start_server
  |> Command_unix.run
