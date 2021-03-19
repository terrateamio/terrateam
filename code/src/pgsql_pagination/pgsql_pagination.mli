(** Given a SQL query, paginate it.  This works by wrapping the existing query
   in a [with] expression and then adding "where" and [order by] and [limit]
   clauses.  This means that all of the columns used for pagination must be
   present as result columns in the query being paginated.

   This supports pagination regardless of the ordering of the columns, however
   this only supports ordering of the tuple representing the columns, so
   arbitrary columns ordering is not supported.  That means all columns will
   have the same ordering.  The difference being, this only supports:

   [ORDER BY (c1, c2, ... cn) ASC/DESC]

   vs

   [ORDER BY c1 ASC, c2 DESC, ... cn ASC/DESC]

   Given a query, the result will be something like:

   [with query as (....) select * from query where (c1 is null or c2 is null or
   ... cn is null or (c1, c2, ... cn) < ($c1, $c2, .. $cn)) ORDER BY (c1, c2,
   ... cn) ASC LIMIT $limit] *)

module Search : sig
  module Col : sig
    type t

    (** Create column, [vname] is the name of the variable in the query, [cname]
       is the name of that column in the returned row. *)
    val create : vname:string -> cname:string -> t
  end

  type t

  (** Create a search.  The order of the list of columns defines the order
     columns will be ordered in.  For example (name, age) is different than
     (age, name) *)
  val create : page_size:int -> dir:[ `Asc | `Desc ] -> Col.t list -> t
end

type 'a t

(** Get the next page given the search and the query. *)
val next :
  Search.t ->
  Pgsql_io.t ->
  ('q, ('r t, [> Pgsql_io.err ]) result Abb.Future.t, 'p, 'r) Pgsql_io.Typed_sql.t ->
  f:'p ->
  'q

(** Get the previous page given the search an query. *)
val prev :
  Search.t ->
  Pgsql_io.t ->
  ('q, ('r t, [> Pgsql_io.err ]) result Abb.Future.t, 'p, 'r) Pgsql_io.Typed_sql.t ->
  f:'p ->
  'q

val results : 'a t -> 'a list

(** Does the query have a next page?  By "next" this means if going to the
   previous page, is there another previous page, or if going to the next page,
   is there another next page. *)
val has_next_page : 'a t -> bool
