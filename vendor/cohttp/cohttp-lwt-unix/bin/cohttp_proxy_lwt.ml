(*{{{ Copyright (c) 2014-2015 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014 Romain Calascibetta <romain.calascibetta@gmail.com>
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

open Printf
open Lwt
open Cohttp
open Cohttp_lwt_unix

let handler ~verbose _ req body =
  let uri = Cohttp.Request.uri req in
  (* Log the request to the console *)
  if verbose then
    eprintf "--> %s %s %s\n%!"
      Cohttp.(Code.string_of_method (Request.meth req))
      (Uri.to_string uri)
      (Sexplib0.Sexp.to_string_hum (Request.sexp_of_t req));
  (* Strip out hop-by-hop connection headers *)
  let headers =
    Request.headers req |> fun h ->
    Header.remove h "accept-encoding" |> fun h ->
    Header.remove h "content-length" |> fun h ->
    Header.remove h "transfer-encoding" |> fun h ->
    Header.remove h "connection" |> fun h ->
    Header.add h "accept-encoding" "identity"
  in
  (* Fetch the remote URI *)
  let meth = Request.meth req in
  Client.call ~headers ~body meth uri >>= fun (resp, body) ->
  if verbose then
    eprintf "<-- %s %s\n%!"
      (Uri.to_string (Request.uri req))
      (Sexplib0.Sexp.to_string_hum (Response.sexp_of_t resp));
  let status = Response.status resp in
  let headers =
    Response.headers resp |> fun h ->
    Header.remove h "transfer-encoding" |> fun h ->
    Header.remove h "content-length" |> fun h -> Header.remove h "connection"
  in
  Server.respond ~headers ~status ~body ()

let sockaddr_of_host_and_port host port =
  let inet_addr = Unix.inet_addr_of_string host in
  Unix.ADDR_INET (inet_addr, port)

let start_proxy port host verbose cert key () =
  printf "Listening for HTTP request on: %s %d\n%!" host port;
  let conn_closed (ch, _conn) =
    printf "Connection %s closed\n%!"
      (Sexplib0.Sexp.to_string_hum (Conduit_lwt_unix.sexp_of_flow ch))
  in
  let callback = handler ~verbose in
  let config = Server.make ~callback ~conn_closed () in
  let mode =
    match (cert, key) with
    | Some c, Some k ->
        `TLS (`Crt_file_path c, `Key_file_path k, `No_password, `Port port)
    | _ -> `TCP (`Port port)
  in
  Server.create ~mode config

let lwt_start_proxy port host level cert key =
  if not @@ Debug.debug_active () then (
    Fmt_tty.setup_std_outputs ();
    Logs.set_level ~all:true level;
    Logs.set_reporter Debug.default_reporter);
  Lwt_main.run (start_proxy port host (level <> None) cert key ())

open Cmdliner

let host =
  let doc = "IP address to listen on." in
  Arg.(value & opt string "0.0.0.0" & info [ "s" ] ~docv:"HOST" ~doc)

let port =
  let doc = "TCP port to listen on." in
  Arg.(value & opt int 8080 & info [ "p" ] ~docv:"PORT" ~doc)

let verb = Logs_cli.level ()

let ssl_cert =
  let doc = "SSL certificate file." in
  Arg.(value & opt (some string) None & info [ "c" ] ~docv:"SSL_CERT" ~doc)

let ssl_key =
  let doc = "SSL key file." in
  Arg.(value & opt (some string) None & info [ "k" ] ~docv:"SSL_KEY" ~doc)

let cmd =
  let info =
    let version = Cohttp.Conf.version in
    let doc = "a simple http proxy" in
    let man =
      [
        `S "DESCRIPTION";
        `P "$(tname) sets up a simple http proxy with lwt as backend";
        `S "BUGS";
        `P
          "Report them via e-mail to <mirageos-devel@lists.xenproject.org>, or \
           on the issue tracker at \
           <https://github.com/mirage/ocaml-cohttp/issues>";
      ]
    in
    Cmd.info "cohttp-proxy" ~version ~doc ~man
  in
  let term =
    Term.(const lwt_start_proxy $ port $ host $ verb $ ssl_cert $ ssl_key)
  in
  Cmd.v info term

let () = exit @@ Cmd.eval cmd
