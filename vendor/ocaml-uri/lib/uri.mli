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

type t

(** This absract type represents a set of safe characters allowed in
    a portion of a URI. Anything not allowed will be percent-encoded.
    Note that different portions of the URI permit a different set of
    allowed characters. *)
type safe_chars

(** This represents the minimal set of safe characters allowed in
    a URI. `[A-Z][a-z]._-` *)
val safe_chars : safe_chars

(** This is the set allowed for the path component *)
val safe_chars_for_path : safe_chars

(** This is the set allowed for the user info component *)
val safe_chars_for_userinfo : safe_chars

(** Percent-encode a string. The [safe_chars] argument defaults to the
    set of characters for a path component, and should be set differently
    for other URI components *)
val pct_encode : ?safe_chars:safe_chars -> string -> string

(** Percent-decode a percent-encoded string *)
val pct_decode : string -> string

(** Convert a percent-encoded string into a URI structure *)
val of_string : string -> t

(** Convert a URI structure into a percent-encoded URI string *)
val to_string : t -> string

(** Get a query string from a URI *)
val query : t -> (string * string) list

(** Make a percent-encoded query string from percent-decoded query tuple *)
val encoded_of_query : (string * string) list -> string

(** Parse a percent-encoded query string into a percent-decoded query tuple *)
val query_of_encoded : string -> (string * string) list

(** Parse a percent-decoded query string into a percent-decoded query tuple *)
val query_of_decoded : string -> (string * string) list

(** Replace the query URI with the supplied list.
  * Input URI is not modified
  *)
val with_query : t -> (string * string) list -> t

val make : ?scheme:string -> ?userinfo:string -> ?host:string ->
  ?port:int -> ?path:string -> ?query:(string * string) list -> 
  ?fragment:string -> unit -> t

(** Get the path component of a URI *)
val path : t -> string

(** Get the scheme component of a URI *)
val scheme : t -> string option

(** Get the userinfo component of a URI *)
val userinfo : t -> string option

(** Get the host component of a URI *)
val host : t -> string option

(** Get the port component of a URI *)
val port : t -> int option

(** Get the fragment component of a URI *)
val fragment : t -> string option

