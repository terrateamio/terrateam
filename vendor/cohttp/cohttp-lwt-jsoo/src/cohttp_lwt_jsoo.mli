(*{{{ Copyright (c) 2014 Andy Ray <andy.ray@ujamjar.com>
 * Copyright (c) 2012-2013 Anil Madhavapeddy <anil@recoil.org>
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

(** {1 HTTP client for JavaScript using XMLHttpRequest.}

    The {!Logs} source name for this module's logger is ["cohttp.lwt.jsoo"]. To
    log the current warnings using the browser's console log, you can write a
    custom reporter or use:

    {[
      let reporter = Logs_browser.console_reporter () in
      Logs.set_reporter reporter
    ]} *)

(** Configuration parameters for the XmlHttpRequest engines *)
module type Params = sig
  val chunked_response : bool
  (** Should the response body data be chunked? *)

  val chunk_size : int
  (** Size of chunks *)

  val convert_body_string : Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t -> string
  (** JavaScript string to OCaml conversion. [Js.to_bytestring] or
      [Js.to_string] *)

  val with_credentials : bool
  (** Whether withCredentials property of XHR is set. *)
end

(** Build an asynchronous engine with chunked/unchucked response data treated as
    raw bytes or UTF *)
module Make_client_async (P : Params) : Cohttp_lwt.S.Client

(** Build a synchronous engine with chunked/unchucked response data treated as
    raw bytes or UTF *)
module Make_client_sync (P : Params) : Cohttp_lwt.S.Client

module Client : Cohttp_lwt.S.Client
(** The [Client] module implements an HTTP client interface using asynchronous
    XmlHttpRequests. The response body is returned in chucked form with 128Kb /
    chunk. Body data is treated as raw bytes. withCredentials property of XHR is
    set to false. *)

module Client_sync : Cohttp_lwt.S.Client
(** The [Client_sync] module implements an HTTP client interface using
    synchronous XmlHttpRequests. The response is not chunked and treated as raw
    bytes. withCredentials property of XHR is set to false. *)
