module Ast : sig
  type pos = {
    lnum : int;
    offset : int;
  }
  [@@deriving show, eq]

  type err = [ `Error of pos option * string * string ] [@@deriving show, eq]
  type t = Mql_ast.t [@@deriving show, eq]

  val limit : t -> int option
  val set_limit : int -> t -> t
  val of_string : string -> (t, [> err ]) result
  val to_string : t -> string
  val expr_to_string : Mql_ast.expr -> string
end

module Build : sig
  (** {1 Expressions} *)

  val id : string -> Mql_ast.expr
  val string : string -> Mql_ast.expr
  val int : int -> Mql_ast.expr
  val float : float -> Mql_ast.expr
  val true_ : Mql_ast.expr
  val false_ : Mql_ast.expr
  val null : Mql_ast.expr
  val eq : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val not_eq : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val gt : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val gte : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val lt : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val lte : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val and_ : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val or_ : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val not_ : Mql_ast.expr -> Mql_ast.expr
  val is : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val is_not : Mql_ast.expr -> Mql_ast.expr -> Mql_ast.expr
  val in_ : Mql_ast.expr -> Mql_ast.expr list -> Mql_ast.expr

  (** {1 Tables} *)

  val table : ?alias:string -> string -> Mql_ast.table_ref

  (** {1 Columns} *)

  val col : ?alias:string -> Mql_ast.expr -> Mql_ast.column
  val columns : Mql_ast.column list -> Mql_ast.select_list
  val star : Mql_ast.select_list

  (** {1 Queries} *)

  val select :
    ?where:Mql_ast.expr ->
    ?joins:Mql_ast.join list ->
    ?group_by:Mql_ast.expr list ->
    ?having:Mql_ast.expr ->
    ?order_by:(Mql_ast.expr * Mql_ast.sort_order option) list ->
    ?limit:int ->
    from:Mql_ast.table_ref list ->
    cols:Mql_ast.select_list ->
    unit ->
    Mql_ast.t
end
