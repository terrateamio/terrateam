(*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

(* Miscellaneous net-helpers used by Cohttp. Ideally, these will disappear
 * into some connection-management framework such as andrenth/release *)

open Lwt.Infix
module IO = Io

type ctx = { ctx : Conduit_lwt_unix.ctx; resolver : Resolver_lwt.t }
[@@deriving sexp_of]

let init ?(ctx = Lazy.force Conduit_lwt_unix.default_ctx)
    ?(resolver = Resolver_lwt_unix.system) () =
  { ctx; resolver }

let default_ctx =
  {
    resolver = Resolver_lwt_unix.system;
    ctx = Lazy.force Conduit_lwt_unix.default_ctx;
  }

let connect_uri ~ctx:{ ctx; resolver } uri =
  Resolver_lwt.resolve_uri ~uri resolver >>= fun endp ->
  Conduit_lwt_unix.endp_to_client ~ctx endp >>= fun client ->
  Conduit_lwt_unix.connect ~ctx client

let close c =
  Lwt.catch
    (fun () -> Lwt_io.close c)
    (fun e ->
      Logs.warn (fun f -> f "Closing channel failed: %s" (Printexc.to_string e));
      Lwt.return_unit)

let close_in ic = Lwt.ignore_result (close ic)
let close_out oc = Lwt.ignore_result (close oc)
let close ic oc = Lwt.ignore_result (close ic >>= fun () -> close oc)
