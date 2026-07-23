(*{{{ Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
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

(** Basic satisfaction of {!Cohttp_lwt.Net} *)

module IO = Io

type ctx = { ctx : Conduit_lwt_unix.ctx; resolver : Resolver_lwt.t }
[@@deriving sexp_of]

val default_ctx : ctx
(** [default_ctx] is the default network context. It uses
    [Conduit_lwt_unix.default_ctx] and [Resolver_lwt_unix.system]. *)

val init : ?ctx:Conduit_lwt_unix.ctx -> ?resolver:Resolver_lwt.t -> unit -> ctx
(** [init ?ctx ?resolver ()] is a network context that is the same as the
    {!default_ctx}, but with either the connection handling or resolution module
    overridden with [ctx] or [resolver] respectively. This is useful to supply a
    {!Conduit_lwt_unix.resolver} with a custom source network interface, or a
    {!Resolver_lwt.t} with a different name resolution strategy (for instance to
    override a hostname to point it to a Unix domain socket). *)

val connect_uri :
  ctx:ctx ->
  Uri.t ->
  (Conduit_lwt_unix.flow
  * Lwt_io.input Lwt_io.channel
  * Lwt_io.output Lwt_io.channel)
  Lwt.t
(** [connect_uri ~ctx uri] starts a {i flow} on the given [uri]. The choice of
    the protocol (with or without encryption) is done by the {i scheme} of the
    given [uri]:

    - If the scheme is [https], we will {b extend} [ctx] to be able to start a
      TLS connection with a default TLS configuration (no authentication) on the
      default or user-specified port.
    - If the scheme is [http], we will {b extend} [ctx] to be able to start a
      simple TCP/IP connection on the default or user-specified port.

    These extensions have the highest priority ([Conduit] will try to initiate a
    communication with them first). By {i extension}, we mean that the user is
    able to fill its own [ctx] and we don't overlap resolution functions from
    the given [ctx]. *)

val close_in : 'a Lwt_io.channel -> unit
val close_out : 'a Lwt_io.channel -> unit
val close : 'a Lwt_io.channel -> 'b Lwt_io.channel -> unit
