type t =
  | With of {
      materialized : bool;
      name : string;
      query : t;
      body : t;
    }
  | Query of {
      body : query_body;
      order_by : order_by option;
      limit : int option;
    }

and query_body =
  | Select of select
  | Union of {
      all : bool;
      left : query_body;
      right : query_body;
    }
  | Paren of t

and select = {
  select_list : select_list;
  from : from_tables;
  joins : join_list;
  where : where option;
  group_by : group_by option;
  having : expr option;
}

and select_list =
  | Star
  | Columns of column list

and column = {
  expr : expr;
  alias : string option;
}

and table = {
  name : string;
  alias : string option;
}

and table_ref =
  | Table_ref of table
  | Unnest of {
      expr : expr;
      alias : string;
    }

and from_tables = table_ref list
and join_list = join list

and join = {
  join_type : join_type;
  table : table;
  on_ : expr;
}

and join_type =
  | Inner
  | Left
  | Right

and where = expr
and group_by = expr list
and order_by = (expr * sort_order option) list

and sort_order =
  | Asc
  | Desc

and tuple = expr list

and expr =
  | Add of (expr * expr)
  | And of (expr * expr)
  | Cast of (expr * string)
  | Concat of (expr * expr)
  | Count of select_list
  | Div of (expr * expr)
  | Eq of (expr * expr)
  | Exists of t
  | False
  | Field_select of (expr * string)
  | Float of float
  | Func of func
  | Gt of (expr * expr)
  | Gte of (expr * expr)
  | Identifier of string
  | Ilike of (expr * expr)
  | In of (expr * tuple)
  | In_query of (expr * t)
  | Index of (expr * expr)
  | Int of int
  | Is of (expr * expr)
  | Is_distinct_from of (expr * expr)
  | Is_not of (expr * expr)
  | Is_not_distinct_from of (expr * expr)
  | Json_obj_query of (expr * string)
  | Json_subset of (expr * expr)
  | Json_text of (expr * expr)
  | Json_val of (expr * expr)
  | Like of (expr * expr)
  | Lt of (expr * expr)
  | Lte of (expr * expr)
  | Mult of (expr * expr)
  | Negate of expr
  | Not of expr
  | Not_eq of (expr * expr)
  | Not_ilike of (expr * expr)
  | Not_like of (expr * expr)
  | Null
  | Or of (expr * expr)
  | String of string
  | Sub of (expr * expr)
  | True
  | Tuple of tuple

and func = {
  name : string;
  args : expr list;
}
[@@deriving show { with_path = false }, eq, yojson]
