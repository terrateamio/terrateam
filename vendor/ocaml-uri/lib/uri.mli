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

type t = {
  scheme: string option;
  userinfo: string option;
  host: string option;
  port: int option;
  path: string;
  query: string option;
  fragment: string option;
}  

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

(** Percent encoded strings should not be encoded twice, so this type
    is an aliased hint to make it clear which functions operate on percent
    encoded strings *)
type pct_encoded = string

(** Percent-encode a string. The [safe_chars] argument defaults to the
    set of characters for a path component, and should be set differently
    for other URI components *)
val pct_encode : ?safe_chars:safe_chars -> string -> pct_encoded

(** Percent-decode a percent-encoded string *)
val pct_decode : pct_encoded -> string

(** Convert a percent-encoded string into a URI structure *)
val of_string : pct_encoded -> t

(** Convert a URI structure into a percent-encoded URI string *)
val to_string : t -> pct_encoded

