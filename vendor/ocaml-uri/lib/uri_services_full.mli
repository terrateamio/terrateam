(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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
 *)

(** Module that maps the IANA well-known ports to and from their textual service names *)

val service_of_tcp_port : int -> string list
(** Convert a TCP port number into a list of IANA well-known service names *)

val service_of_udp_port : int -> string list
(** Convert a UDP port number into a list of IANA well-known service names *)

val tcp_port_of_service : string -> int list
(** Convert a IANA well-known service name into a list of valid TCP port numbers *)

val udp_port_of_service : string -> int list
(** Convert a IANA well-known service name into a list of valid UDP port numbers *)

val tcp_port_of_uri : ?default:string -> Uri.t -> int option
(** Extract a TCP port from a URI, using a default service if the URI does not contain a scheme *)

val udp_port_of_uri : ?default:string -> Uri.t -> int option
(** Extract a UDP port from a URI, using a default service if the URI does not contain a scheme *)

val known_tcp_services : string list
(** List of known TCP services.
    These keys are guaranteed to match in the rest of the lookup functions. *)

val known_udp_services : string list
(** List of known UDP services.
    These keys are guaranteed to match in the rest of the lookup functions. *)

val known_services : (string * string list) list
(** Association list of [protocol * service list].  Usually populated with
    at least "tcp" and "udp" keys for those respective protocols. *)
