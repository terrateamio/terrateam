(*
 * Copyright (c) 2012-2017 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazazagnaire.org>
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
 * %%NAME%% %%VERSION%%
 *)

(** Serve static HTTP sites from a Mirage key-value store. *)

(** Plain HTTP file serving from a read-only key-value store. *)
module HTTP (FS : Mirage_kv.RO) (S : Cohttp_lwt.S.Server) : sig
  (** [start http_port ?request_fn fs http] will start a static HTTP server
      listening on [http_port]. The files to serve will be looked up from the
      [fs] key-value store.

      If [request_fn] is supplied, the URI and default header set (including the
      MIME content-type header) will be passed to it and the response used as
      the response header set instead. *)

  val start :
    http_port:int ->
    ?request_fn:(Uri.t -> Cohttp.Header.t -> Cohttp.Header.t) ->
    FS.t ->
    ([> `TCP of int ] -> S.t -> 'a) ->
    'a
end
