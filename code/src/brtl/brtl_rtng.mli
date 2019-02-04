module Handler : sig
  type t = ((string, unit) Brtl_ctx.t ->
            (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t)
end

module Route : sig
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

  (** Extract a variable from the body *)
  val (/*) : ('f, 'a -> 'r) t -> 'a Query.t -> ('f, 'r) t

  (** Create a route of a URL and a function that matches the types being
      extracted. *)
  val route : ('f, 'r) t -> 'f -> 'r Route.t

  (** Infix operator for {!route}. *)
  val (-->) : ('f, 'r) t -> 'f -> 'r Route.t

  (** Given a list of routes, match an input URI and execute the associated route
      function.  If no matches are found, execute the [default] function. *)
  val match_ctx :
    default:((string, unit) Brtl_ctx.t -> 'r) ->
    'r Route.t list ->
    (string, unit) Brtl_ctx.t ->
    'r
end

module Method : sig
  type t = Cohttp.Code.meth
end

type t

val create :
  default:Handler.t ->
  (Method.t * Handler.t Route.Route.t) list ->
  t

val route : (string, unit) Brtl_ctx.t -> t -> Handler.t
