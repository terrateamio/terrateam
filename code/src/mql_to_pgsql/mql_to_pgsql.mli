module Page : sig
  type dir =
    | Affirm  (** The page is going in the direction of the query. *)
    | Negate  (** The page is going in the opposite direction of the query *)
  [@@deriving show, eq, yojson]

  type t = {
    dir : dir;
    cursor : Yojson.Safe.t;
  }
  [@@deriving show, eq, yojson]
end

module Pages : sig
  type t = {
    prev : Page.t;
    next : Page.t;
  }
  [@@deriving show, eq]
end

module Schema : sig
  module Column : sig
    module Type_ : sig
      type t =
        | Bigint
        | Bool
        | Complex of string
        | Float
        | Integer
        | Jsonb
        | Smallint
        | Text
        | Timestamptz
        | Uuid
      [@@deriving show, eq]
    end

    type t

    val make : name:string -> type_:Type_.t -> unit -> t
  end

  module Table : sig
    type t

    val make : ?table_expr:bool -> name:string -> Column.t list -> t
  end

  type t [@@deriving to_yojson]

  val make : Table.t list -> t
end

type of_mql_err =
  [ `Table_access_err of string
  | `Ambiguous_column_err of string
  | `Unknown_column_err of string
  | `Func_access_err of string
  | `Cast_err of string
  | `Invalid_identifier_err of string
  | `Type_mismatch_err of Schema.Column.Type_.t * Mql_ast.expr
  ]
[@@deriving show, eq]

type pages_err =
  [ `Column_not_in_row_err of string
  | `Order_by_col_not_identifier_err of Mql_ast.expr
  ]
[@@deriving show, eq]

type apply_page_err =
  [ `Order_by_mismatch_err
  | `Missing_order_by_err
  | `Missing_group_by_err
  | `Missing_cursor_col_err of string
  | `Order_by_col_not_identifier_err of Mql_ast.expr
  | `Page_invalid_type_err of Yojson.Safe.t
  ]
[@@deriving show, eq]

type t [@@deriving show, eq]

val query : t -> Mql.Ast.t
val texts : t -> string CCVector.vector
val json : t -> string CCVector.vector
val smallints : t -> int CCVector.vector
val integers : t -> Int32.t CCVector.vector
val bigints : t -> Int64.t CCVector.vector
val floats : t -> float CCVector.vector

(** Given an AST, a defined schema, and some other constraints, turn the AST into a valid query that
    can be safely executed via pgsql. *)
val of_mql :
  ?max_limit:int ->
  ?func_white_list:string list ->
  ?cast_white_list:string list ->
  schema:Schema.t ->
  Mql.Ast.t ->
  (t, [> of_mql_err ]) result

(** A query can only automatically be paginated if it has an [ORDER BY] clause. Using the results we
    construct cursors for the previous and next page. This does not validate that there ARE actually
    more pages, simply if you wanted to a previous or next page, what the cursor value would be. It
    is up to the caller to decide if there are previous pages. [None] is returned if the query is
    lacks an [ORDER BY]. *)
val pages : Yojson.Safe.t list -> t -> (Pages.t option, [> pages_err ]) result

(** Given a query and a page, apply the page to the query. Fail if the query does not have any
    corresponding *)
val apply_page : Page.t -> Mql_ast.t -> (Mql_ast.t, [> apply_page_err ]) result
