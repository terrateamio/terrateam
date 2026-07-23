(*{{{ Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
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
open Cohttp_async

let show_headers h =
  Cohttp.Header.iter (fun k v -> Logs.info (fun m -> m "%s: %s%!" k v)) h

let make_net_req uri meth' body () =
  let meth = Cohttp.Code.method_of_string meth' in
  let uri = Uri.of_string uri in
  let headers = Cohttp.Header.of_list [ ("connection", "close") ] in
  Client.call meth ~headers ~body:Body.(of_string body) uri
  >>= fun (res, body) ->
  show_headers (Cohttp.Response.headers res);
  body
  |> Body.to_pipe
  |> Pipe.iter ~f:(fun b ->
         Stdlib.print_string b;
         return ())

let _ =
  (* enable logging to stdout *)
  Fmt_tty.setup_std_outputs ();
  Logs.set_level @@ Some Logs.Debug;
  Logs.set_reporter (Logs_fmt.reporter ());
  let open Async_command in
  async_spec ~summary:"Fetch URL and print it"
    Spec.(
      empty
      +> anon ("url" %: string)
      +> flag "-X" (optional_with_default "GET" string) ~doc:" Set HTTP method"
      +> flag "data-binary"
           (optional_with_default "" string)
           ~doc:" Data to send when using POST")
    make_net_req
  |> Command_unix.run
