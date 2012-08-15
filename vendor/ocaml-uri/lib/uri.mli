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

type component = [
  `Scheme
| `Authority
| `Userinfo (* subcomponent of authority in some schemes *)
| `Host (* subcomponent of authority in some schemes *)
| `Path
| `Query
| `Fragment
]

(** Percent-encode a string. The [scheme] argument defaults to 'http' and
    the [component] argument defaults to `Path *)
val pct_encode : ?scheme:string -> ?component:component -> string -> string

(** Percent-decode a percent-encoded string *)
val pct_decode : string -> string

(** Convert a percent-encoded string into a URI structure *)
val of_string : string -> t

(** Convert a URI structure into a percent-encoded URI string *)
val to_string : t -> string

(** Resolve a URI against a default scheme and base URI *)
val resolve : string -> t -> t -> t

(** Get a query string from a URI *)
val query : t -> (string * string) list

(** Make a percent-encoded query string from percent-decoded query tuple *)
val encoded_of_query : (string * string) list -> string

(** Parse a percent-encoded query string into a percent-decoded query tuple *)
val query_of_encoded : string -> (string * string) list

(** Replace the query URI with the supplied list.
  * Input URI is not modified
  *)
val with_query : t -> (string * string) list -> t

(** Add a query parameter to the input query URI.
  * Input URI is not modified
  *)
val add_query_param : t -> (string * string) -> t

(** Add a query parameter list to the input query URI.
  * Input URI is not modified
  *)
val add_query_params : t -> (string * string) list -> t

val make : ?scheme:string -> ?userinfo:string -> ?host:string ->
  ?port:int -> ?path:string -> ?query:(string * string) list -> 
  ?fragment:string -> unit -> t

(** Get the path component of a URI *)
val path : t -> string

(** Get the path and query components of a URI *)
val path_and_query : t -> string

(** Get the scheme component of a URI *)
val scheme : t -> string option

(** Get the userinfo component of a URI *)
val userinfo : t -> string option

(** Get the host component of a URI *)
val host : t -> string option

(** Get the host component of a URI, with a default
  * supplied if one is not present *)
val host_with_default: ?default:string -> t -> string

(** Get the port component of a URI *)
val port : t -> int option

(** Get the fragment component of a URI *)
val fragment : t -> string option

