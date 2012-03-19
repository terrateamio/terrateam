(*
 * Copyright (c) 2012 Richard Mortier <mort@cantab.net>
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

(** Handle IPv4 and IPv6 addresses as used in URIs. 

    @author Richard Mortier <mort\@cantab.net>
*)

(** Type alias for a byte. *)
type byte

(** Convert {! byte} to {! Int32}. *)
val byte_to_int32 : byte -> int32

(** Type alias for a sequence of bytes. *)
type bytes
val bytes : string -> bytes
val bytes_to_string : bytes -> string

(** Simple representation of an IPv4 address as {! Int32}. *)
type ipv4 = Int32.t

(** Standard dotted quad string representation of an IPv4 address. *)
val ipv4_to_string : ipv4 -> string

(** Parse standard dotted quad string representation of an IPv4 address. *)
val string_to_ipv4 : string -> ipv4

(** Generate numeric IPv4 address from a packed bytestring. *)
val bytes_to_ipv4 : bytes -> ipv4

(** Simple representation of an IPv6 address (128 bits). *)
type ipv6 = int32 * int32 * int32 * int32

(** Standard string representation of an IPv6 address.
    Note this is not yet canonicalised per RFC 5952. *)
val ipv6_to_string : ipv6 -> string

(** Generate numeric -- 4-tuple of Int32, as above -- IPv6 address from packed
    bytestring. *)
val bytes_to_ipv6 : bytes -> ipv6
