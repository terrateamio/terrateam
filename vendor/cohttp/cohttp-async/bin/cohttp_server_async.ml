(*{{{ Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
  }}}*)

open Base
open Async_kernel
open Async_unix
open Cohttp_async
open Cohttp_server

let method_filter meth (res, body) =
  match meth with `HEAD -> return (res, `Empty) | _ -> return (res, body)

let serve_file ~docroot ~uri =
  Cohttp.Path.resolve_local_file ~docroot ~uri |> Server.respond_with_file

let serve ~info ~docroot ~index uri path =
  (* Get a canonical filename from the URL and docroot *)
  let file_name = Cohttp.Path.resolve_local_file ~docroot ~uri in
  try_with (fun () ->
      Unix.stat file_name >>= fun stat ->
      Logs.debug (fun f ->
          f "%s" (Sexp.to_string_hum (Unix.Stats.sexp_of_t stat)));
      match stat.Unix.Stats.kind with
      (* Get a list of current files and map to HTML *)
      | `Directory -> (
          let path_len = String.length path in
          if Int.(path_len <> 0) && Char.(path.[path_len - 1] <> '/') then
            Server.respond_with_redirect (Uri.with_path uri (path ^ "/"))
            (* Check if the index file exists *)
          else
            Sys.file_exists (file_name / index) >>= function
            | `Yes ->
                (* Serve the index file directly *)
                let uri = Uri.with_path uri (path / index) in
                serve_file ~docroot ~uri
            | `No | `Unknown ->
                (* Do a directory listing *)
                Sys.ls_dir file_name
                >>= Deferred.List.map ~how:`Parallel ~f:(fun f ->
                        let file_name = file_name / f in
                        try_with (fun () ->
                            Unix.stat file_name >>| fun stat ->
                            (Some stat.Unix.Stats.kind, stat.Unix.Stats.size, f))
                        >>| function
                        | Ok v -> v
                        | Error _ -> (None, 0L, f))
                >>= fun listing ->
                html_of_listing uri path
                  (sort ((Some `Directory, 0L, "..") :: listing))
                  info
                |> Server.respond_string)
      (* Serve the local file contents *)
      | `File -> serve_file ~docroot ~uri
      (* Any other file type is simply forbidden *)
      | `Socket | `Block | `Fifo | `Char | `Link ->
          Server.respond_string ~status:`Forbidden
            (html_of_forbidden_unnormal path info))
  >>= function
  | Ok res -> return res
  | Error exn -> (
      match Monitor.extract_exn exn with
      | Unix.Unix_error (Unix.Error.ENOENT, "stat", p) ->
          if String.equal p ("((filename " ^ file_name ^ "))") (* Really? *)
          then
            Server.respond_string ~status:`Not_found
              (html_of_not_found path info)
          else raise exn
      | _ -> raise exn)

(** HTTP handler *)
let handler ~info ~docroot ~index ~body:_ _sock req =
  let uri = Cohttp.Request.uri req in
  let path = Uri.path uri in
  (* Log the request to the console *)
  printf "%s %s%!" Cohttp.(Code.string_of_method (Request.meth req)) path;
  match Request.meth req with
  | (`GET | `HEAD) as meth ->
      serve ~info ~docroot ~index uri path >>= method_filter meth
  | meth ->
      let meth = Cohttp.Code.string_of_method meth in
      let allowed = "GET, HEAD" in
      let headers = Cohttp.Header.of_list [ ("allow", allowed) ] in
      Server.respond_string ~headers ~status:`Method_not_allowed
        (html_of_method_not_allowed meth allowed path info)

let determine_mode cert_file_path key_file_path =
  (* Determines if the server runs in http or https *)
  match (cert_file_path, key_file_path) with
  | Some c, Some k -> `OpenSSL (`Crt_file_path c, `Key_file_path k)
  | None, None -> `TCP
  | _ -> failwith "Error: must specify both certificate and key for HTTPS"

let start_server docroot port index cert_file key_file verbose () =
  (* enable logging to stdout *)
  Fmt_tty.setup_std_outputs ();
  Logs.set_level @@ if verbose then Some Logs.Debug else Some Logs.Info;
  Logs.set_reporter (Logs_fmt.reporter ());
  let mode = determine_mode cert_file key_file in
  let mode_str = match mode with `OpenSSL _ -> "HTTPS" | `TCP -> "HTTP" in
  Logs.info (fun f -> f "Listening for %s requests on %d" mode_str port);
  let info = Printf.sprintf "Served by Cohttp/Async listening on %d" port in
  Server.create
    ~on_handler_error:
      (`Call
        (fun addr exn ->
          Logs.err (fun f -> f "Error from %s" (Socket.Address.to_string addr));
          Logs.err (fun f -> f "%s" @@ Exn.to_string exn)))
    ~mode
    (Tcp.Where_to_listen.of_port port)
    (handler ~info ~docroot ~index)
  >>= fun _serv -> Deferred.never ()

let () =
  let open Async_command in
  Command_unix.run
  @@ async_spec ~summary:"Serve the local directory contents via HTTP or HTTPS"
       Spec.(
         empty
         +> anon (maybe_with_default "." ("docroot" %: string))
         +> flag "-p"
              (optional_with_default 8080 int)
              ~doc:"port TCP port to listen on"
         +> flag "-i"
              (optional_with_default "index.html" string)
              ~doc:"file Name of index file in directory"
         +> flag "-cert-file" (optional string) ~doc:"File of cert for https"
         +> flag "-key-file" (optional string)
              ~doc:"File of private key for https"
         +> flag "-v" no_arg ~doc:" Verbose logging output to console")
       start_server
