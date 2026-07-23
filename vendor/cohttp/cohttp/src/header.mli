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

(** Associative list representing HTTP headers. Order of transmission is
    preserved, which implies that headers with same name are neither removed or
    concataned by default (see [clean_dup] to do that). *)
type t [@@deriving sexp]
(** The type for HTTP headers. *)

val init : unit -> t
(** [init ()] constructs a fresh, empty list of HTTP headers. *)

val is_empty : t -> bool
(** [is_empty h] tests whether HTTP headers [h] are empty or not. *)

val of_list : (string * string) list -> t
(** [of_list l] construct a fresh headers from the content of [l] and in same
    order. [to_list] and [of_list] are defined such as [to_list (of_list l) = l]
    is true with case insensitive comparison. *)

val to_list : t -> (string * string) list
(** [to_list h] converts HTTP headers [h] to a list. Order and case is
    preserved.

    {e Invariant (with case insensitive comparison):} [to_list (of_list l) = l] *)

val init_with : string -> string -> t
(** [init_with k v] construct a fresh HTTP headers with a single header with
    name [k] and value [v]. *)

val add : t -> string -> string -> t
(** [add h k v] adds the header name [k] and it associated value [v] at the end
    of header list [h]. *)

val add_list : t -> (string * string) list -> t
(** [add_list h l] adds in order all header pairs contained in [l] to the header
    list [h].

    {e Invariant (with case insensitive comparison):}
    [to_list (add_list h l) = to_list h @ l] *)

val add_multi : t -> string -> string list -> t
(** [add_multi h k vs] add multiple header pairs with same name [h] and values
    contained in [vs] in [h]. The new headers are in the same order that in
    [vs].

    {e Invariant:} [get_multi (add_multi h k vs) k = (get_multi h k) @ vs] *)

val add_opt : t option -> string -> string -> t
(** [add_opt hopt k v] adds the header [(k, v)] to [h] if [hopt] is [Some h], or
    constructs a fresh header list containing this single header if [hopt] is
    [None]. *)

val add_unless_exists : t -> string -> string -> t
(** [add_unless_exists h k v] adds [(k, v)] to [h] unless the header name [k] is
    already present in the header. *)

val add_opt_unless_exists : t option -> string -> string -> t
(** [add_opt_unless_exists h k v] adds [(k, v)] to [h] if [hopt] is [Some h]
    unless the header name [k] is already present in the headers. If [h] is
    [None] then a fresh header list is constructed containing the header
    [(k, v)]. *)

val remove : t -> string -> t
(** [remove h k] removes every values associated to the header name [k] from
    [h]. *)

val replace : t -> string -> string -> t
(** [replace h k v] replaces the last added value of [k] from [h] and removed
    all other occurences of [k] if it exists. Otherwise it adds [(k, v)] to [h].

    {e Invariant:} [forall h, k, v. get_multi (replace h k v) = \[ v \]] *)

val mem : t -> string -> bool
(** [mem h k] returns [true] if the header name [k] appears in [h] and [false]
    otherwise. *)

val compare : t -> t -> int
(** [compare h h'] is the structural comparison of two [Header] values. *)

val get : t -> string -> string option
(** [get h k] returns [Some v] where [v] is the last added value associated with
    [k] in [h] if it exists and [None] otherwise *)

val get_multi : t -> string -> string list
(** [get_multi h k] returns a list of all values associated with [k] in [h] in
    order they appear in it. *)

val get_multi_concat : ?list_value_only:bool -> t -> string -> string option
(** [get_multi_concat h k] returns [Some v] if there is at least one value
    associated with [k] in [h] and [None] otherwise. [v] is the concatenation of
    all values paired with [k] in [h], separated by a comma and in order they
    appear in [h].

    The optional argument [?list_value_only] is [false] by default. If it is
    [true] and there is at least one value associated to [k], the returned value
    is the concatenated values only if [k] is a header that can have multiple
    values (like transfer-encoding or accept). Otherwise, the returned value is
    the last value paired with [k] in [h].

    {e Invariant:}
    [forall h, k not a list-value header. get_multi_concat ~list-value-only:true h k = get h k] *)

val update : t -> string -> (string option -> string option) -> t
(** [update h k f] returns an header list containing the same headers as [h],
    except for the header name [k]. Depending on the value of [v] where [v] is
    [f (get h k)], the header pair [(k, v)] is added, removed or updated.

    - If [v] is [None], the last occurence of [k] in [h] is removed;

    - If [v] is [Some w] then the last value paired with [k] in [h] is replaced
      by [w] if it exists. Otherwise, the pair [(k, w)] is added;

    - If [k] was already associated last in [h] to a value that is physically
      equal to [w], [h] is returned unchanged. *)

val update_all : t -> string -> (string list -> string list) -> t
(** [update_all h k f] returns an header list containing the same headers as
    [h], except for the header [k]. Depending on the list of values [vs] where
    [vs] is [f (get_multi h k)], the values associated to the header [k] are
    added, removed or updated.

    - If [vs] is an empty list, every occurences of the header [k] in [h] are
      removed;

    - If [vs] is a non-empty list, all values previously associated to [k] are
      removed and all values in [vs] are added with [add_multi];

    - If [k] was already associated in [h] to a list that is equal to [vs], [h]
      is returned unchanged. *)

val iter : (string -> string -> unit) -> t -> unit
val map : (string -> string -> string) -> t -> t
val fold : (string -> string -> 'a -> 'a) -> t -> 'a -> 'a

val to_lines : t -> string list
(** [to_lines h] returns header fieds as a list of lines. Beware that each line
    ends with "\r\n" characters. *)

val to_frames : t -> string list
(** [to_frames h] returns the same as {!to_lines} but lines do not end with
    "\r\n" characters. *)

val to_string : t -> string

val clean_dup : t -> t
(** [clean_dup h] cleans duplicates in [h] following
    {{:https://tools.ietf.org/html/rfc7230#section-3.2.2} RFC7230§3.2.2}; if a
    duplicated header can not have multiple values, only the last value is kept
    in place. Otherwise, the values are concatenated and place at the first
    position the header is encountered in [h].

    Already concatenated values (like [anhost.com, anotherhost.com] in the
    example below) are not affected by [clean_dup]. For example,

    {v
    transfer-encoding: gzip
    host: afirsthost.com
    connection: keep-alive
    host: anhost.com, anotherhost.com
    transfer-encoding: chunked
    v}

    becomes

    {v
    transfer-encoding: gzip, chunked
    connection: keep-alive
    host: anhost.com, anotherhost.com
    v}

    Finally, following {{:https://tools.ietf.org/html/rfc7230#section-3.2.2}
    RFC7230§3.2.2}, the header [Set-cookie] is treated as an exception and
    ignored by [clean_dup]. *)

val get_content_range : t -> Int64.t option
val get_media_type : t -> string option
val get_connection_close : t -> bool

val get_acceptable_media_ranges :
  t -> (Accept.media_range * Accept.p list) Accept.qlist

val get_acceptable_charsets : t -> Accept.charset Accept.qlist
val get_acceptable_encodings : t -> Accept.encoding Accept.qlist
val get_acceptable_languages : t -> Accept.language Accept.qlist
val get_transfer_encoding : t -> Transfer.encoding
val add_transfer_encoding : t -> Transfer.encoding -> t
val add_authorization : t -> Auth.credential -> t
val get_authorization : t -> Auth.credential option
val add_authorization_req : t -> Auth.challenge -> t
val is_form : t -> bool
val get_location : t -> Uri.t option
val add_links : t -> Link.t list -> t
val get_links : t -> Link.t list

val user_agent : string
(** The User-Agent header used by this library, including the version of cohttp. *)

val prepend_user_agent : t -> string -> t
(** Prepend [user_agent] to the product token already declared in the
    "User-Agent" field (if any). *)

val connection : t -> [ `Keep_alive | `Close | `Unknown of string ] option

val pp_hum : Format.formatter -> t -> unit
(** Human-readable output, used by the toplevel printer *)
