(*
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
 *)

(** Uniform Resource Identifier handling that is RFC3986-compliant. *)

(** A single URI that is a compact sequence of characters that identifies
    an abstract or physical resource. *)
type t [@@deriving sexp]

type component = [
    `Scheme
  | `Authority
  | `Userinfo (** subcomponent of authority in some schemes *)
  | `Host (** subcomponent of authority in some schemes *)
  | `Path
  | `Query
  | `Query_key
  | `Query_value
  | `Fragment
] [@@deriving sexp]

(** {3 Core functionality } *)

(** The empty (zero length) URI reference. Useful for constructing
    URIs piece-by-piece. *)
val empty : t

(** Comparator ordering by host, scheme, port, userinfo, path, query,
    and finally fragment. Designed to produce a reasonable sort order. *)
val compare : t -> t -> int

(** [equal a b] is [compare a b = 0]. *)
val equal : t -> t -> bool

(** Percent-encode a string. The [scheme] argument defaults to 'http' and
    the [component] argument defaults to `Path *)
val pct_encode : ?scheme:string -> ?component:component -> string -> string

(** Percent-decode a percent-encoded string *)
val pct_decode : string -> string

(** Parse a URI string literal into a URI structure. A bare string will be
    interpreted as a path; a string prefixed with `//` will be interpreted as a
    host.
*)
val of_string : string -> t

(** Convert a URI structure into a percent-encoded URI string *)
val to_string : t -> string

(** Resolve a URI against a default scheme and base URI *)
val resolve : string -> t -> t -> t

(** Canonicalize a URI according to Sec 6.2.3 "Scheme-Based
    Normalization". This transform is more aggressive than the
    standard URI-generic normalization automatically done. In
    particular, HTTP(S) URIs with empty path components will have
    their path components set to "/". Some applications like web
    servers may rely on the distinction between a path-less and a
    root-path URI to distinguish request URIs (e.g. OPTIONS * vs
    OPTIONS /).

    @see <https://tools.ietf.org/html/rfc3986#section-6.2.3> RFC 3986.6.2.3
*)
val canonicalize : t -> t

(** Make a URI from supplied components. If userinfo or port are
    supplied without host, an empty host is added. If path is supplied
    and userinfo, host, or port is also supplied, path is made
    absolute but not resolved. *)
val make : ?scheme:string -> ?userinfo:string -> ?host:string ->
  ?port:int -> ?path:string -> ?query:(string * string list) list ->
  ?fragment:string -> unit -> t

(** Functional update for a URI using the supplied components.  If a component
    is unspecified then it will be unchanged.  If a component is supplied as
    [None] then the component will be removed in the returned URI.  If a
    component is supplied as [Some x] then [x] will be added if it does not
    exist in the source URI or replaced if it does exist. *)
val with_uri : ?scheme:string option -> ?userinfo:string option ->
  ?host:string option -> ?port:int option -> ?path:string option ->
  ?query:(string * string list) list option -> ?fragment:string option -> t -> t

(** {3 Query functions }

    The query string API attempts to accommodate conventional query
    string representations (i.e. [?key0=value0&key1=value1]) while
    maximally exposing any meaning in those representations. For
    example, it is not necessarily the case that [/] and [/?] are
    equivalent to a web server. In the former case, we observe a zero
    query string whereas in the latter case, we observe a query string
    with a single key, [""] and a zero value. Compare this with [/?=]
    which has a single key and a single empty value,
    [""]. Additionally, some query functions return lists of values
    for a key. These list values are extracted from a {b single} key
    with a comma-separated value list. If a query string has multiple
    identical keys, you must use {! query} to retrieve the entirety of
    the structured query string.
*)

(** Get a query string from a URI *)
val query : t -> (string * string list) list

(** Get a verbatim query string from a URI. If the provenance of the
    URI is a string and its query component has not been updated, this
    is the literal query string as parsed. Otherwise, this is the
    composition of {!query} and {!encoded_of_query} *)
val verbatim_query : t -> string option

(** Make a percent-encoded query string from percent-decoded query tuple *)
val encoded_of_query : ?scheme:string -> (string * string list) list -> string

(** Parse a percent-encoded query string into a percent-decoded query tuple *)
val query_of_encoded : string -> (string * string list) list

(** Replace the query URI with the supplied list.
    Input URI is not modified
*)
val with_query : t -> (string * string list) list -> t

(** Replace the query URI with the supplied singleton query list.
    Input URI is not modified
*)
val with_query' : t -> (string * string) list -> t

(** [get_query_param' q key] returns the list of values for the
    [key] parameter in query [q].  Note that an empty list is not the
    same as a [None] return value.  For a query [foo], the mapping is:
    - [/] returns None
    - [/?foo] returns Some []
    - [/?foo=] returns [Some [""]]
    - [/?foo=bar] returns [Some ["bar"]]
    - [/?foo=bar,chi] returns [Some ["bar","chi"]]

    Query keys can be duplicated in the URI, in which case the first
    one is returned.  If you want to resolve duplicate keys, obtain
    the full result set with {! query } instead.
*)
val get_query_param' : t -> string -> string list option

(** [get_query_param q key] returns the value found for a [key] in
     query [q].  If there are multiple values for the key, then the
     first one is returned. *)
val get_query_param: t -> string -> string option

(** Add a query parameter to the input query URI.
    Input URI is not modified
*)
val add_query_param : t -> (string * string list) -> t

(** Add a query parameter to the input singleton query URI.
    Input URI is not modified
*)
val add_query_param' : t -> (string * string) -> t

(** Add a query parameter list to the input query URI.
    Input URI is not modified
*)
val add_query_params : t -> (string * string list) list -> t

(** Add a query singleton parameter list to the input query URI.
    Input URI is not modified
*)
val add_query_params' : t -> (string * string) list -> t

(** Remove a query key from the input query URI.
    Input URI is not modified, and no error is generated if the
    key does not already exist in the URI.
*)
val remove_query_param : t -> string -> t

(** {3 Component getters and setters } *)

(** Get the encoded path component of a URI *)
val path : t -> string

(** Get the encoded path and query components of a URI *)
val path_and_query : t -> string

(** Replace the path URI with the supplied encoded path.
    If a host is present in the supplied URI, the path is made absolute but not
    resolved. If the path is empty, the path component is removed.
    Input URI is not modified *)
val with_path : t -> string -> t

(** Get the scheme component of a URI *)
val scheme : t -> string option

(** Replace the scheme portion of the URI with the supplied [scheme].
    Input URI is not modified *)
val with_scheme : t -> string option -> t

(** Get the userinfo component of a URI *)
val userinfo : t -> string option

(** Replace the userinfo portion of the URI with the supplied [string option].
    If no host is present in the supplied URI, an empty host is added.
    Input URI is not modified. *)
val with_userinfo : t -> string option -> t

(** Get the username component of a URI *)
val user : t -> string option

(** Get the password component of a URI *)
val password : t -> string option

(** Replace the password portion of the URI with the supplied [string option].
    If no host is present in the supplied URI, an empty host is added.
    Input URI is not modified.
*)
val with_password : t -> string option -> t

(** Get the host component of a URI *)
val host : t -> string option

(** Replace the host component of the URI.
    Input URI is not modified. *)
val with_host: t -> string option -> t

(** Get the host component of a URI, with a default supplied if one is
    not present *)
val host_with_default: ?default:string -> t -> string

(** Get the port component of a URI *)
val port : t -> int option

(** Replace the port component of the URI with the supplied port.
    If no host is present in the supplied URI, an empty host is added.
    Input URI is not modified. *)
val with_port : t -> int option -> t

(** Get the fragment component of a URI *)
val fragment : t -> string option

(** Replace the fragment component of a URI with the supplied fragment.
    Input URI is not modified *)
val with_fragment : t -> string option -> t

(** {3 Utilities } *)

(**  Human-readable output, used by the toplevel printer *)
val pp_hum : Format.formatter -> t -> unit
