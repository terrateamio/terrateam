(** {1 Overview}

   This module is heavily based on {{:https://github.com/Drup/furl} Furl} by
   Drup.

   Furi implements formatted URIs.  Formatted URIs are URIs where with patterns
   are specified in them that can be extracted.  The formatted URIs can then be
   connected to functions and the input parameters to those functions correspond
   to the extracted patterns.

   For example, given the following pattern:

   [let path = Furi.(rel / "foo" /% Path.int)]

   [let f i = ....]

   This can then be applied to a function that takes an [int].  This is done
   with the [-->] operator.

   [let route = path --> f]

   Route's can then be combined and used to match of list of routes:

   [let default uri = ...]

   [match_uri ~default [route] some_uri]

   If [some_uri] looks like ["/foo/124"] then [f] will be executed otherwise
   [default] will be executed.

   {1 URI Routing}

   Given the following URI patterns.

   {[let search_rt = Furi.(rel / "search" /? Query.string "query")

let hello_rt = Furi.(rel / "hello" /% Path.string /% Path.string)

let age_rt = Furi.(rel / "age" /% Path.int)

let age_height_rt = Furi.(rel / "age_height" /? Query.int "age" /? Query.int "height")]}

   And the following handler functions:

   {[let handle_search query = ...

let handle_hello first_name last_name = ...

let handle_age age = ...

let handle_age_height age height = ...]}

   They can be combined into a routing table like:

   {[let routes = [ search_rt --> handle_search
             ; hello_rt --> handle_hello
             ; age_rt --> handle_age
             ; age_height_rt --> handle_age_height
             ]]}

   Finally, given a URI, they can be matched with:

   [let result = Furi.match_uri ~default routes some_uri]

   {2 URI Matching Semantics}

   URIs are matched in the order they appear in the [routes] list.

   The path portion of a URI must be completely consumed for the match to be
   considered successful.

   All specified query parameters must match however extra query parameters are
   ignored.  For example if a URI in the above example had a query parameter
   named [query] and [foo], the [search_rt] pattern would still match.

   {2 URI Matching Gotchas}

   Furi does nothing special to handle URIs with a trailing slash.  A pattern
   such as [Furi.(rel / "foo")] will only match a URI like
   [http://localhost/foo].  If one wants to match [http://localhost/foo/] the
   URI pattern can be written as [Furi.(rel / "foo" / "")].

   Beware query matches with the same path.  Because query values are not
   exhausted during the test for a matching pattern, if the path is the same
   between to queries, the queries must be listed in the routes list from
   most-specific to least.  For example, consider the following two patterns:
   [let homepage_rt = Furi.rel] and [let search_rt = Furi.(rel /? Query.string
   "q")].  In the routes list, these must be in the below order otherwise the
   homepage will always match even when a query parameter [q] is present.

   {[[search_rt --> search; homepage_rt --> homepage]]}

   Similarly, if there are multiple query searches with the same path but
   different numbers of query parameters, they must be in order of most specific
   to least specific.

   {2 Path and Query values}

   The {!Path} and {!Query} modules provide functions to create pattern
   matchers.  Some standard types are provided however the [ud] function is used
   to construct new types.  [ud] takes a function (and in the case of {!Query} a
   name and a function) that takes a string which is the URI path segment or the
   query string, and returns an option type where [None] means the pattern did
   not match.  For example, {!Path.string} can be implemented as [Path.ud (fun x
   -> Some x)].

   The function passed into [ud] is wrapped in a [try] block and if the function
   throws an exception, it is the same as if it evaluated to [None].

   For paths, only the path segment is input to the function.  For example,
   given the URI pattern:

   [Furi.(rel / "foo" /% Path.ud (fun s -> Some s))]

   For the URI [http://localhost/foo/baz], the input to the function would only
   be the string ["baz"].

*)
(** A URL pattern. *)
type ('f, 'r) t

(** Extractions from the URI path. *)
module Path : sig
  type 'a t

  (** A user defined extraction.  The function is passed the string which
     contains a segment of a URI path, which is the content between two slashes
     or at the end of the string. *)
  val ud : (string -> 'a option) -> 'a t

  (** Extract a string from the path. *)
  val string : string t

  (** Extract an int from the path. *)
  val int : int t
end

(** Extractions for query parameters. *)
module Query : sig
  type 'a t

  (** Given the name of a query parameter, pass the value into the string and
     convert it to the type. *)
  val ud : string -> (string -> 'a option) -> 'a t

  (** Extract a string from the query parameter. *)
  val string : string -> string t

  (** Extract an int from the query parameters. *)
  val int : string -> int t
end

(** Represents a route, which is a URL pattern and the function it should be
   applied to. *)
module Route : sig
  type 'r t
end

(** The start of a path. *)
val rel : ('r, 'r) t

(** Match a string portion of the path. *)
val (/) : ('f, 'r) t -> string -> ('f, 'r) t

(** Extract a variable from the path. *)
val (/%) : ('f, 'a -> 'r) t -> 'a Path.t -> ('f, 'r) t

(** Extract a variable from the query. *)
val (/?) : ('f, 'a -> 'r) t -> 'a Query.t -> ('f, 'r) t

(** Create a route of a URL and a function that matches the types being
   extracted. *)
val route : ('f, 'r) t -> 'f -> 'r Route.t

(** Infix operator for {!route}. *)
val (-->) : ('f, 'r) t -> 'f -> 'r Route.t

(** Given a list of routes, match an input URI and execute the associated route
   function.  If no matches are found, execute the [default] function. *)
val match_uri : default:(Uri.t -> 'r) -> 'r Route.t list -> Uri.t -> 'r