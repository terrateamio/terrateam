module String_map = Sln_map.String

module Col_expr = struct
  type t =
    | Id of string
    | Field of (string * string)
    | Count_star
  [@@deriving ord]
end

module Col_expr_map = CCMap.Make (Col_expr)

(* The MQL function allow-list.

   SECURITY -- a function named here may be called by any MQL query, so only
   pure, value-level scalar and aggregate functions belong in this list. An
   entry MUST NOT: read the filesystem, server settings, or system catalogs
   (e.g. [pg_read_file], [current_setting], [pg_ls_dir]); reach the network
   (e.g. the [dblink] family); enable a denial-of-service (e.g. [pg_sleep],
   [generate_series]); or return a set of rows, which would multiply result
   rows and break [LIMIT] and pagination (e.g. [unnest], [jsonb_array_elements],
   [regexp_matches], [jsonb_object_keys]). Every entry below operates only on
   the values passed to it. *)
let default_func_white_list =
  [
    (* Conditional *)
    "coalesce";
    "nullif";
    "greatest";
    "least";
    (* Aggregates *)
    "sum";
    "avg";
    "min";
    "max";
    "bool_and";
    "bool_or";
    "string_agg";
    "array_agg";
    "json_agg";
    "jsonb_agg";
    (* String *)
    "lower";
    "upper";
    "length";
    "trim";
    "ltrim";
    "rtrim";
    "substr";
    "replace";
    "split_part";
    "strpos";
    "starts_with";
    "concat";
    "concat_ws";
    "regexp_replace";
    "to_char";
    (* Numeric *)
    "abs";
    "ceil";
    "floor";
    "round";
    "trunc";
    (* JSON *)
    "to_jsonb";
    "json_build_object";
    "jsonb_build_object";
    "json_build_array";
    "jsonb_build_array";
    "json_array_length";
    "jsonb_array_length";
    "json_typeof";
    "jsonb_typeof";
    "jsonb_extract_path_text";
    "jsonb_pretty";
    (* Array *)
    "array_length";
    "cardinality";
    "array_to_string";
    (* Date/time *)
    "now";
    "date_trunc";
    "date_part";
    "age";
  ]

let default_cast_white_list =
  [
    "bigint";
    "bool";
    "boolean";
    "integer";
    "jsonb";
    "real";
    "smallint";
    "text";
    "timestamptz";
    "uuid";
  ]

module Page = struct
  type dir =
    | Affirm
    | Negate
  [@@deriving show, eq, yojson]

  type t = {
    dir : dir;
    cursor : Yojson.Safe.t;
  }
  [@@deriving show, eq, yojson]
end

module Pages = struct
  type t = {
    prev : Page.t;
    next : Page.t;
  }
  [@@deriving show, eq]
end

module Schema = struct
  module Column = struct
    module Type_ = struct
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
      [@@deriving show { with_path = false }, eq]

      let to_string = function
        | Bigint -> "bigint"
        | Bool -> "bool"
        | Complex type_ -> type_
        | Float -> "float"
        | Integer -> "integer"
        | Jsonb -> "jsonb"
        | Smallint -> "smallint"
        | Text -> "text"
        | Timestamptz -> "timestamptz"
        | Uuid -> "uuid"
    end

    type t = {
      name : string;
      type_ : Type_.t;
    }

    let make ~name ~type_ () = { name; type_ }
  end

  module Table = struct
    type t = {
      name : string;
      columns : Column.t String_map.t;
      table_expr : bool;
    }

    let make ?(table_expr = false) ~name columns =
      {
        name;
        columns =
          String_map.of_list @@ CCList.map (fun ({ Column.name; _ } as c) -> (name, c)) columns;
        table_expr;
      }
  end

  type t = { tables : Table.t String_map.t }

  let make tables =
    { tables = String_map.of_list @@ CCList.map (fun ({ Table.name; _ } as t) -> (name, t)) tables }

  let to_yojson { tables } =
    `Assoc
      [
        ( "tables",
          `Assoc
            (CCList.map (fun (name, { Table.name = _; columns; table_expr = _ }) ->
                 ( name,
                   `Assoc
                     [
                       ( "columns",
                         `Assoc
                           (CCList.map (fun (col_name, { Column.name = _; type_ }) ->
                                ( col_name,
                                  `Assoc [ ("type", `String (Column.Type_.to_string type_)) ] ))
                           @@ String_map.to_list columns) );
                     ] ))
            @@ String_map.to_list tables) );
      ]
end

module Rw = struct
  type t = {
    texts : string CCVector.vector;
    json : string CCVector.vector;
    smallints : int CCVector.vector;
    integers : Int32.t CCVector.vector;
    bigints : Int64.t CCVector.vector;
    floats : float CCVector.vector;
    func_white_list : string list;
    cast_white_list : string list;
    schema : Schema.t;
    col_name_to_columns : (string * Schema.Column.t) list String_map.t;
    tab_name_to_table : Schema.Table.t String_map.t;
  }
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

exception Rw_exn of of_mql_err

type t = {
  query : Mql.Ast.t;
  rw : Rw.t; [@opaque] [@equal fun _ _ -> true]
}
[@@deriving show, eq]

let query t = t.query
let texts t = t.rw.Rw.texts
let json t = t.rw.Rw.json
let smallints t = t.rw.Rw.smallints
let integers t = t.rw.Rw.integers
let bigints t = t.rw.Rw.bigints
let floats t = t.rw.Rw.floats

(* Identifier charset guard (defense in depth).

   Identifiers (table/column/alias/CTE/function/cast-type names) are rendered
   verbatim by [Mql.Ast.to_string] and the result is text-substituted into the
   SQL template. Today the MQL lexer only admits [A-Za-z_][A-Za-z0-9_]*
   identifiers, so nothing dangerous can reach here -- but [of_mql] re-checks
   every identifier so that a future lexer change (quoted identifiers, unicode,
   dotted names, ...) cannot silently turn identifier rendering into a
   SQL-injection vector. This fails closed: any out-of-charset identifier is
   rejected with [`Invalid_identifier_err]. *)
let valid_identifier s =
  (not (CCString.is_empty s))
  && (match s.[0] with
    | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true
    | _ -> false)
  && CCString.for_all
       (function
         | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
         | _ -> false)
       s

let check_identifier s = if not (valid_identifier s) then raise (Rw_exn (`Invalid_identifier_err s))

let rec check_identifiers_ast =
  let open Mql_ast in
  function
  | With { materialized = _; name; query; body } ->
      check_identifier name;
      check_identifiers_ast query;
      check_identifiers_ast body
  | Query { body; order_by; limit = _ } ->
      check_identifiers_query_body body;
      CCOption.iter (CCList.iter (fun (e, _) -> check_identifiers_expr e)) order_by

and check_identifiers_query_body =
  let open Mql_ast in
  function
  | Select s -> check_identifiers_select s
  | Union { all = _; left; right } ->
      check_identifiers_query_body left;
      check_identifiers_query_body right
  | Paren q -> check_identifiers_ast q

and check_identifiers_select { Mql_ast.select_list; from; joins; where; group_by; having } =
  check_identifiers_select_list select_list;
  CCList.iter check_identifiers_table_ref from;
  CCList.iter check_identifiers_join joins;
  CCOption.iter check_identifiers_expr where;
  CCOption.iter (CCList.iter check_identifiers_expr) group_by;
  CCOption.iter check_identifiers_expr having

and check_identifiers_select_list =
  let open Mql_ast in
  function
  | Star -> ()
  | Columns cols ->
      CCList.iter
        (fun { expr; alias } ->
          check_identifiers_expr expr;
          CCOption.iter check_identifier alias)
        cols

and check_identifiers_table { Mql_ast.name; alias } =
  check_identifier name;
  CCOption.iter check_identifier alias

and check_identifiers_table_ref =
  let open Mql_ast in
  function
  | Table_ref t -> check_identifiers_table t
  | Unnest { expr; alias } ->
      check_identifiers_expr expr;
      check_identifier alias

and check_identifiers_join { Mql_ast.join_type = _; table; on_ } =
  check_identifiers_table table;
  check_identifiers_expr on_

and check_identifiers_expr =
  let open Mql_ast in
  function
  | Add (e1, e2)
  | And (e1, e2)
  | Concat (e1, e2)
  | Div (e1, e2)
  | Eq (e1, e2)
  | Gt (e1, e2)
  | Gte (e1, e2)
  | Ilike (e1, e2)
  | Index (e1, e2)
  | Is (e1, e2)
  | Is_distinct_from (e1, e2)
  | Is_not (e1, e2)
  | Is_not_distinct_from (e1, e2)
  | Json_subset (e1, e2)
  | Json_text (e1, e2)
  | Json_val (e1, e2)
  | Like (e1, e2)
  | Lt (e1, e2)
  | Lte (e1, e2)
  | Mult (e1, e2)
  | Not_eq (e1, e2)
  | Not_ilike (e1, e2)
  | Not_like (e1, e2)
  | Or (e1, e2)
  | Sub (e1, e2) ->
      check_identifiers_expr e1;
      check_identifiers_expr e2
  | Cast (e, type_) ->
      check_identifiers_expr e;
      check_identifier type_
  | Count select_list -> check_identifiers_select_list select_list
  | Exists q -> check_identifiers_ast q
  | False | True | Null | Float _ | Int _ | String _ -> ()
  | Field_select (e, field) ->
      check_identifiers_expr e;
      check_identifier field
  | Func { name; args } ->
      check_identifier name;
      CCList.iter check_identifiers_expr args
  | Identifier s -> check_identifier s
  | In (e, tuple) ->
      check_identifiers_expr e;
      CCList.iter check_identifiers_expr tuple
  | In_query (e, q) ->
      check_identifiers_expr e;
      check_identifiers_ast q
  | Json_obj_query (e, _path) ->
      (* [_path] is a string literal operand of [#>>], not an identifier;
         it is escaped at render time, not emitted as an identifier. *)
      check_identifiers_expr e
  | Negate e | Not e -> check_identifiers_expr e
  | Tuple tuple -> CCList.iter check_identifiers_expr tuple

let lookup_col_type ?table ~rw col =
  match table with
  | Some table_name -> (
      match String_map.find_opt table_name rw.Rw.tab_name_to_table with
      | Some table -> (
          match
            CCOption.or_
              ~else_:
                (if table.Schema.Table.table_expr then Some (Schema.Column.Type_.Complex "unknown")
                 else None)
            @@ CCOption.map (fun column -> column.Schema.Column.type_)
            @@ String_map.find_opt col table.Schema.Table.columns
          with
          | Some type_ -> Some type_
          | None -> raise (Rw_exn (`Unknown_column_err col)))
      | None -> raise (Rw_exn (`Table_access_err table_name)))
  | None -> (
      match String_map.find_opt col rw.Rw.col_name_to_columns with
      | Some [] -> None
      | Some [ (_, col) ] -> Some col.Schema.Column.type_
      | Some (_ :: _) -> raise (Rw_exn (`Ambiguous_column_err col))
      | None
        (* An unrecognised bare column is only tolerated when a table with an
         unknown column set (a CTE / [unnest] / subquery-derived table) is
         actually IN SCOPE for this select -- the column could belong to it. *)
        when String_map.exists
               (fun _ { Schema.Table.table_expr; _ } -> table_expr)
               rw.Rw.tab_name_to_table -> None
      | None -> raise (Rw_exn (`Unknown_column_err col)))

let identifier_type ~rw =
  let open Mql_ast in
  function
  | Identifier id -> lookup_col_type ~rw id
  | Field_select (Identifier id, c) -> lookup_col_type ~rw ~table:id c
  | _ -> None

let rw_lit_bigint ~rw =
  let open Mql_ast in
  function
  | Int i ->
      CCVector.push rw.Rw.bigints (Int64.of_int i);
      let idx = CCVector.size rw.Rw.bigints in
      Index (Identifier "$bigints", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Bigint, v)))

let rw_lit_float ~rw =
  let open Mql_ast in
  function
  | Float fl ->
      CCVector.push rw.Rw.floats fl;
      let idx = CCVector.size rw.Rw.floats in
      Index (Identifier "$floats", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Float, v)))

let rw_lit_integer ~rw =
  let open Mql_ast in
  function
  | Int i ->
      CCVector.push rw.Rw.integers (Int32.of_int i);
      let idx = CCVector.size rw.Rw.integers in
      Index (Identifier "$integers", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Integer, v)))

let rw_lit_json ~rw =
  let open Mql_ast in
  function
  | String s ->
      CCVector.push rw.Rw.json s;
      let idx = CCVector.size rw.Rw.json in
      Index (Identifier "$json", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Jsonb, v)))

let rw_lit_smallint ~rw =
  let open Mql_ast in
  function
  | Int i ->
      CCVector.push rw.Rw.smallints i;
      let idx = CCVector.size rw.Rw.smallints in
      Index (Identifier "$smallints", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Smallint, v)))

let rw_lit_text ~rw =
  let open Mql_ast in
  function
  | String s ->
      CCVector.push rw.Rw.texts s;
      let idx = CCVector.size rw.Rw.texts in
      Index (Identifier "$texts", Int idx)
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Text, v)))

let rw_lit_timestamptz ~rw =
  let open Mql_ast in
  function
  | String s ->
      CCVector.push rw.Rw.texts s;
      let idx = CCVector.size rw.Rw.texts in
      Cast (Index (Identifier "$texts", Int idx), "timestamptz")
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Timestamptz, v)))

let rw_lit_uuid ~rw =
  let open Mql_ast in
  function
  | String s ->
      CCVector.push rw.Rw.texts s;
      let idx = CCVector.size rw.Rw.texts in
      Cast (Index (Identifier "$texts", Int idx), "uuid")
  | (Null | True | False) as e -> e
  | v -> raise (Rw_exn (`Type_mismatch_err (Schema.Column.Type_.Uuid, v)))

let rw_lit ~rw type_ expr =
  match type_ with
  | Schema.Column.Type_.Bigint -> rw_lit_bigint ~rw expr
  | Schema.Column.Type_.Bool -> expr
  | Schema.Column.Type_.Float -> rw_lit_float ~rw expr
  | Schema.Column.Type_.Integer -> rw_lit_integer ~rw expr
  | Schema.Column.Type_.Jsonb -> rw_lit_json ~rw expr
  | Schema.Column.Type_.Smallint -> rw_lit_smallint ~rw expr
  | Schema.Column.Type_.Text -> rw_lit_text ~rw expr
  | Schema.Column.Type_.Timestamptz -> rw_lit_timestamptz ~rw expr
  | Schema.Column.Type_.Complex _ -> expr
  | Schema.Column.Type_.Uuid -> rw_lit_uuid ~rw expr

let rec rw_expr ~rw =
  let open Mql_ast in
  function
  | Add (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Add (e1, e2)) e1 e2
  | And (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> And (e1, e2)) e1 e2
  | Cast (e1, type_) when CCList.mem ~eq:CCString.equal type_ rw.Rw.cast_white_list ->
      Cast (rw_expr ~rw e1, type_)
  | Cast (_e1, type_) -> raise (Rw_exn (`Cast_err type_))
  | Concat (e1, e2) -> Concat (rw_expr ~rw e1, rw_expr ~rw e2)
  | Count _ as e -> e
  | Div (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Div (e1, e2)) e1 e2
  | Eq (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Eq (e1, e2)) e1 e2
  | Exists q -> Exists (rw_ast ~rw q)
  | False -> False
  | Field_select (Identifier table, field) as e ->
      (* Qualified column reference [table.field]. Validate it against the
         schema; [Identifier table] is a table reference (not a column) so it
         is not recursively rewritten. [lookup_col_type] raises
         [`Table_access_err] / [`Unknown_column_err] as appropriate and is a
         no-op for [table_expr] tables (CTEs/unnest), whose columns are
         genuinely unknown. *)
      ignore (lookup_col_type ~rw ~table field);
      e
  | Field_select (e1, field) -> Field_select (rw_expr ~rw e1, field)
  | Float _ as e -> rw_lit_float ~rw e
  | Func { name; args = _ } when not @@ CCList.mem ~eq:CCString.equal name rw.Rw.func_white_list ->
      raise (Rw_exn (`Func_access_err name))
  | Func { name = _; args = [] } as e -> e
  | Func { name; args } -> Func { name; args = CCList.map (rw_expr ~rw) args }
  | Gt (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Gt (e1, e2)) e1 e2
  | Gte (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Gte (e1, e2)) e1 e2
  | Identifier id as e ->
      (* Bare column reference. Validate it against the schema for every
         position it can appear in (select list, group by, order by, ...), not
         just comparison operands. [lookup_col_type] raises
         [`Unknown_column_err] / [`Ambiguous_column_err], and tolerates unknown
         columns only when a [table_expr] table is in scope. *)
      ignore (lookup_col_type ~rw id);
      e
  | Ilike (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Ilike (e1, e2)) e1 e2
  | In (e, tuple) -> (
      (* Coerce literal list elements to the column's type, mirroring
         [rw_bin_op] for [=]. Without this, [uuid_col in ('...')] emits an
         uncast text placeholder and PostgreSQL rejects the type mismatch.
         List elements that are themselves columns are rewritten as-is. *)
      match identifier_type ~rw e with
      | Some type_ ->
          let rw_elem elem =
            match identifier_type ~rw elem with
            | Some _ -> rw_expr ~rw elem
            | None -> rw_lit ~rw type_ elem
          in
          In (e, CCList.map rw_elem tuple)
      | None -> In (rw_expr ~rw e, CCList.map (rw_expr ~rw) tuple))
  | In_query (e, q) -> In_query (rw_expr ~rw e, rw_ast ~rw q)
  | Index (e1, e2) -> Index (rw_expr ~rw e1, rw_expr ~rw e2)
  | Int _ as e -> rw_lit_bigint ~rw e
  | Is (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Is (e1, e2)) e1 e2
  | Is_distinct_from (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Is_distinct_from (e1, e2)) e1 e2
  | Is_not (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Is_not (e1, e2)) e1 e2
  | Is_not_distinct_from (e1, e2) ->
      rw_bin_op ~rw ~c:(fun e1 e2 -> Is_not_distinct_from (e1, e2)) e1 e2
  | Json_obj_query (e1, s) -> Json_obj_query (rw_expr ~rw e1, s)
  | Json_subset (e1, e2) -> Json_subset (rw_expr ~rw e1, rw_expr ~rw e2)
  | Json_text (e1, e2) -> Json_text (rw_expr ~rw e1, rw_expr ~rw e2)
  | Json_val (e1, e2) -> Json_val (rw_expr ~rw e1, rw_expr ~rw e2)
  | Like (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Like (e1, e2)) e1 e2
  | Lt (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Lt (e1, e2)) e1 e2
  | Lte (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Lte (e1, e2)) e1 e2
  | Mult (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Mult (e1, e2)) e1 e2
  | Negate e1 -> Negate (rw_expr ~rw e1)
  | Not e1 -> Not (rw_expr ~rw e1)
  | Not_eq (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Not_eq (e1, e2)) e1 e2
  | Not_ilike (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Not_ilike (e1, e2)) e1 e2
  | Not_like (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Not_like (e1, e2)) e1 e2
  | Null -> Null
  | Or (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Or (e1, e2)) e1 e2
  | String _ as e -> rw_lit_text ~rw e
  | Sub (e1, e2) -> rw_bin_op ~rw ~c:(fun e1 e2 -> Sub (e1, e2)) e1 e2
  | True -> True
  | Tuple tuple -> Tuple (CCList.map (rw_expr ~rw) tuple)

and rw_bin_op ~rw ~c e1 e2 =
  match (identifier_type ~rw e1, identifier_type ~rw e2) with
  | Some _, Some _ | None, None -> c (rw_expr ~rw e1) (rw_expr ~rw e2)
  | Some type_, None -> c e1 (rw_lit ~rw type_ e2)
  | None, Some type_ -> c (rw_lit ~rw type_ e1) e2

and rw_select_list ~rw =
  let open Mql_ast in
  function
  | Star -> Star
  | Columns cols ->
      Columns (CCList.map (fun { expr; alias } -> { expr = rw_expr ~rw expr; alias }) cols)

and rw_from ~rw from =
  let open Mql_ast in
  CCList.map
    (function
      | Table_ref t -> Table_ref t
      | Unnest { expr; alias } -> Unnest { expr = rw_expr ~rw expr; alias })
    from

and rw_joins ~rw joins =
  let open Mql_ast in
  CCList.map
    (fun ({ join_type = _; table = _; on_ } as j) -> { j with on_ = rw_expr ~rw on_ })
    joins

and rw_where ~rw e = rw_expr ~rw e
and rw_group_by ~rw exprs = CCList.map (rw_expr ~rw) exprs
and rw_having ~rw e = rw_expr ~rw e
and rw_order_by ~rw order_by = CCList.map (fun (expr, sort) -> (rw_expr ~rw expr, sort)) order_by

and col_alias_to_expr select_list =
  let open Mql_ast in
  match select_list with
  | Star -> String_map.empty
  | Columns cols ->
      CCListLabels.fold_left
        ~init:String_map.empty
        ~f:(fun acc col ->
          match col with
          | { expr; alias = Some alias } -> String_map.add alias expr acc
          | _ -> acc)
        cols

and expr_to_col_alias select_list =
  let open Mql_ast in
  match select_list with
  | Star -> Col_expr_map.empty
  | Columns cols ->
      CCListLabels.fold_left
        ~init:Col_expr_map.empty
        ~f:(fun acc col ->
          match col with
          | { expr = Identifier col; alias = Some alias } ->
              Col_expr_map.add (Col_expr.Id col) alias acc
          | { expr = Field_select (Identifier table, col); alias = Some alias } ->
              Col_expr_map.add (Col_expr.Field (table, col)) alias acc
          | { expr = Count Star; alias = Some alias } ->
              Col_expr_map.add Col_expr.Count_star alias acc
          | _ -> acc)
        cols

and rw_ast ~rw =
  let open Mql_ast in
  function
  | With { materialized; name; query; body } ->
      let query = rw_ast ~rw query in
      let schema =
        {
          Schema.tables =
            String_map.add
              name
              (Schema.Table.make ~table_expr:true ~name [])
              rw.Rw.schema.Schema.tables;
        }
      in
      let body = rw_ast ~rw:{ rw with Rw.schema } body in
      With { materialized; name; query; body }
  | Query { body; order_by; limit } ->
      (* Rewrite the body; [scope_rw] is the (leftmost) select-core's scope, used to
         rewrite the query-level [order_by] (whose columns name the body's output). *)
      let body, scope_rw = rw_query_body ~rw body in
      let order_by = CCOption.map (rw_order_by ~rw:scope_rw) order_by in
      Query { body; order_by; limit }

(* Each select-core in the body -- in every UNION branch and every parenthesized
   sub-query -- is rewritten here, so its tables/columns/functions/casts are all
   schema-validated. UNION introduces no path to an unvalidated table. *)
and rw_query_body ~rw =
  let open Mql_ast in
  function
  | Select sc ->
      let sc, scope_rw = rw_select_core ~rw sc in
      (Select sc, scope_rw)
  | Paren q -> (Paren (rw_ast ~rw q), rw)
  | Union { all; left; right } ->
      let left, left_scope = rw_query_body ~rw left in
      let right, _ = rw_query_body ~rw right in
      (Union { all; left; right }, left_scope)

and rw_select_core ~rw select =
  let open Mql_ast in
  let { select_list; from; joins; where; group_by; having } = select in
  let schema = rw.Rw.schema in
  let tab_alias_to_table =
    (* Resolve each aliased table name to its schema table. An unknown table
       must raise [`Table_access_err] (a caught [Rw_exn]) -- using
       [String_map.find] here let an aliased unknown table escape as an
       uncaught [Not_found], surfacing as a 500 instead of a 400. *)
    String_map.map (fun table_name ->
        match String_map.find_opt table_name schema.Schema.tables with
        | Some table -> table
        | None -> raise (Rw_exn (`Table_access_err table_name)))
    @@ String_map.union
         (fun _ _ v -> Some v)
         (String_map.of_list
         @@ CCList.filter_map
              (function
                | Table_ref { name; alias = Some alias } -> Some (alias, name)
                | Table_ref { alias = None; _ } -> None
                | Unnest _ -> None)
              from)
         (String_map.of_list
         @@ CCList.filter_map
              (function
                | { join_type = _; table = { name; alias = Some alias }; on_ = _ } ->
                    Some (alias, name)
                | _ -> None)
              joins)
  in
  let unnest_tables =
    String_map.of_list
    @@ CCList.filter_map
         (function
           | Unnest { alias; _ } -> Some (alias, Schema.Table.make ~table_expr:true ~name:alias [])
           | Table_ref _ -> None)
         from
  in
  let tab_name_to_table =
    String_map.union (fun _ _ v -> Some v) unnest_tables
    @@ String_map.union (fun _ _ v -> Some v) tab_alias_to_table
    @@ String_map.union
         (fun _ _ v -> Some v)
         (String_map.of_list
         @@ CCList.filter_map
              (function
                | Table_ref { name; alias = _ } -> (
                    match String_map.find_opt name schema.Schema.tables with
                    | Some table -> Some (name, table)
                    | None -> raise (Rw_exn (`Table_access_err name)))
                | Unnest _ -> None)
              from)
         (String_map.of_list
         @@ CCList.map
              (fun { table = { name; _ }; join_type = _; on_ = _ } ->
                match String_map.find_opt name schema.Schema.tables with
                | Some table -> (name, table)
                | None -> raise (Rw_exn (`Table_access_err name)))
              joins)
  in
  let expr_to_col_alias = expr_to_col_alias select_list in
  let col_name_to_columns =
    let all_cols =
      String_map.fold
        (fun _ table acc ->
          String_map.fold
            (fun _ column acc ->
              String_map.add_to_list column.Schema.Column.name (table.Schema.Table.name, column) acc)
            table.Schema.Table.columns
            acc)
        tab_name_to_table
        String_map.empty
    in
    String_map.map (fun columns ->
        let module M = CCMap.Make (struct
          type t = string * string [@@deriving ord]
        end) in
        Iter.to_list
        @@ M.values
        @@ M.of_list
        @@ CCList.map
             (fun ((table_name, column) as v) -> ((table_name, column.Schema.Column.name), v))
             columns)
    @@ String_map.union
         (fun _ v1 v2 -> Some (v1 @ v2))
         (Col_expr_map.fold
            (fun expr alias acc ->
              match expr with
              | Col_expr.Id col ->
                  String_map.add
                    alias
                    (CCOption.get_or ~default:[] @@ String_map.find_opt col all_cols)
                    acc
              | Col_expr.Field (tab, col) -> (
                  match String_map.find_opt tab tab_name_to_table with
                  | Some tab ->
                      CCOption.map_or ~default:acc (fun column ->
                          String_map.add_to_list col (tab.Schema.Table.name, column) acc)
                      @@ String_map.find_opt col tab.Schema.Table.columns
                  | None ->
                      (* TODO: Do the right thing here *)
                      acc)
              | Col_expr.Count_star ->
                  (* A count-star output column aliased as [alias]. Record the
                     alias with an empty column list so that referring to it
                     (e.g. in an order-by) resolves instead of raising
                     [`Unknown_column_err] now that bare identifiers are
                     validated. *)
                  String_map.add alias [] acc)
            expr_to_col_alias
            String_map.empty)
         all_cols
  in
  (* Correlation: the freshly-computed scope shadows, but does not erase, the
         enclosing query's scope. For a top-level / CTE-definition query the incoming
         maps are empty, so this is a no-op there; for an In_query/Exists subquery the
         incoming maps are the enclosing select's scope, so correlated references
         resolve. The subquery's own tables are still validated against [rw.schema]. *)
  let tab_name_to_table =
    String_map.union (fun _ _outer inner -> Some inner) rw.Rw.tab_name_to_table tab_name_to_table
  in
  let col_name_to_columns =
    String_map.union
      (fun _ _outer inner -> Some inner)
      rw.Rw.col_name_to_columns
      col_name_to_columns
  in
  let rw = { rw with Rw.schema; col_name_to_columns; tab_name_to_table } in
  ( {
      select_list = rw_select_list ~rw select_list;
      from = rw_from ~rw from;
      joins = rw_joins ~rw joins;
      where = CCOption.map (rw_where ~rw) where;
      group_by = CCOption.map (rw_group_by ~rw) group_by;
      having = CCOption.map (rw_having ~rw) having;
    },
    rw )

let mk_rw ~func_white_list ~cast_white_list schema =
  {
    Rw.texts = CCVector.create ();
    json = CCVector.create ();
    smallints = CCVector.create ();
    integers = CCVector.create ();
    bigints = CCVector.create ();
    floats = CCVector.create ();
    func_white_list;
    cast_white_list;
    schema;
    col_name_to_columns = String_map.empty;
    tab_name_to_table = String_map.empty;
  }

let rec rw_limit ~max_limit =
  let open Mql_ast in
  function
  | With { materialized; name; query; body } ->
      With { materialized; name; query; body = rw_limit ~max_limit body }
  | Query { body; order_by; limit } ->
      Query
        {
          body;
          order_by;
          limit = Some (CCOption.map_or ~default:max_limit (CCInt.min max_limit) limit);
        }

let of_mql
    ?(max_limit = 20)
    ?(func_white_list = default_func_white_list)
    ?(cast_white_list = default_cast_white_list)
    ~schema
    ast =
  try
    (* Fail closed on any out-of-charset identifier before doing anything
       else; see [check_identifiers_ast]. *)
    check_identifiers_ast ast;
    let rw = mk_rw ~func_white_list ~cast_white_list schema in
    let query = rw_limit ~max_limit @@ rw_ast ~rw ast in
    Ok { query; rw }
  with Rw_exn (#of_mql_err as err) -> Error err

let assert_order_by_cols_can_paginate order_by =
  let module A = Mql_ast in
  let open CCResult.Infix in
  CCResult.map_l
    (function
      | A.Identifier _, _ | A.Field_select _, _ | A.Count A.Star, _ -> Ok ()
      | v, _ -> Error (`Order_by_col_not_identifier_err v))
    order_by
  >>= fun _ -> Ok ()

let lookup_col_in_row expr_to_col_alias expr col row =
  match Col_expr_map.find_opt expr expr_to_col_alias with
  | Some alias -> (
      match CCList.Assoc.get ~eq:CCString.equal alias @@ Yojson.Safe.Util.to_assoc row with
      | None -> (
          match CCList.Assoc.get ~eq:CCString.equal col @@ Yojson.Safe.Util.to_assoc row with
          | None -> Error (`Column_not_in_row_err col)
          | Some ((`Null | `String _ | `Int _ | `Float _) as v) -> Ok (col, v)
          | _ -> assert false)
      | Some ((`Null | `String _ | `Int _ | `Float _) as v) -> Ok (alias, v)
      | _ -> assert false)
  | None -> (
      match CCList.Assoc.get ~eq:CCString.equal col @@ Yojson.Safe.Util.to_assoc row with
      | None -> Error (`Column_not_in_row_err col)
      | Some ((`Null | `String _ | `Int _ | `Float _) as v) -> Ok (col, v)
      | _ -> assert false)

let mk_cursor expr_to_col_alias row order_by =
  let module A = Mql_ast in
  let open CCResult.Infix in
  CCResult.map_l
    (function
      | A.Identifier col, _ -> lookup_col_in_row expr_to_col_alias (Col_expr.Id col) col row
      | A.Field_select (A.Identifier table, col), _ ->
          lookup_col_in_row expr_to_col_alias (Col_expr.Field (table, col)) col row
      | A.Count A.Star, _ -> lookup_col_in_row expr_to_col_alias Col_expr.Count_star "count" row
      | _ -> assert false)
    order_by
  >>= fun cursor -> Ok (`Assoc cursor)

(* Walk past any leading [With] CTEs to the [Query], returning its body and order_by. *)
let rec query_parts = function
  | Mql_ast.With { body; _ } -> query_parts body
  | Mql_ast.Query { body; order_by; _ } -> (body, order_by)

let pages results t =
  let module A = Mql_ast in
  match results with
  | [] -> Ok None
  | results -> (
      let min_row = CCList.hd results in
      let max_row = CCList.hd @@ CCList.rev results in
      match query_parts t.query with
      | A.Select { A.select_list; _ }, Some order_by ->
          let open CCResult.Infix in
          assert_order_by_cols_can_paginate order_by
          >>= fun () ->
          let expr_to_col_alias = expr_to_col_alias select_list in
          mk_cursor expr_to_col_alias min_row order_by
          >>= fun min_cursor ->
          mk_cursor expr_to_col_alias max_row order_by
          >>= fun max_cursor ->
          Ok
            (Some
               {
                 Pages.prev = { Page.dir = Page.Negate; cursor = min_cursor };
                 next = { Page.dir = Page.Affirm; cursor = max_cursor };
               })
      (* No order_by, or a UNION / parenthesized body -- not paginable. *)
      | _ -> Ok None)

(* Look up the cursor value for [col] and return it as an AST literal. *)
let mk_page_value page col =
  match CCList.Assoc.get ~eq:CCString.equal col @@ Yojson.Safe.Util.to_assoc page.Page.cursor with
  | None -> Error (`Missing_cursor_col_err col)
  | Some `Null -> Ok Mql_ast.Null
  | Some (`String s) -> Ok (Mql_ast.String s)
  | Some (`Float fl) -> Ok (Mql_ast.Float fl)
  | Some (`Int i) -> Ok (Mql_ast.Int i)
  | Some ((`Tuple _ | `Bool _ | `Intlit _ | `Variant _ | `Assoc _ | `List _) as v) ->
      Error (`Page_invalid_type_err v)

(* Keyset (lexicographic) pagination predicate over the whole ORDER BY tuple.

   For ORDER BY c1, c2, ..., cn going forward this is the standard OR-expansion

     c1 > v1
     OR (c1 = v1 AND c2 > v2)
     OR (c1 = v1 AND c2 = v2 AND ... AND cn >= vn)

   -- a true lexicographic comparison, NOT the flat [c1 >= v1 AND c2 >= v2 ...]
   conjunction, which under-selects whenever a trailing column is not monotonic
   across the leading one (e.g. instances.address restarting per state).  The
   final column stays inclusive (>=/<=) so the cursor row is re-selected and
   then dropped by the endpoint's [trim_rows]; every earlier column is strict.

   Direction is per-column: [greater] combines the page direction (Affirm /
   Negate) with the column's own Asc/Desc.  Equality links use [IS NULL] for a
   null cursor value and plain [=] otherwise, so a NULL in a leading order
   column chains (as [ck IS NULL]) instead of annihilating the conjunction,
   while non-null links stay index-friendly. *)
let lex_keyset page_dir cols =
  let module A = Mql_ast in
  let greater dir =
    match (page_dir, dir) with
    | Page.Affirm, (None | Some A.Asc) | Page.Negate, Some A.Desc -> true
    | Page.Affirm, Some A.Desc | Page.Negate, (None | Some A.Asc) -> false
  in
  let strict expr value dir = if greater dir then A.Gt (expr, value) else A.Lt (expr, value) in
  let inclusive expr value dir = if greater dir then A.Gte (expr, value) else A.Lte (expr, value) in
  let equal expr = function
    | A.Null -> A.Is (expr, A.Null)
    | value -> A.Eq (expr, value)
  in
  let n = CCList.length cols in
  let term k (expr, value, dir) =
    let cmp = if k = n - 1 then inclusive expr value dir else strict expr value dir in
    CCList.take k cols
    |> CCListLabels.fold_right ~init:cmp ~f:(fun (e, v, _) acc -> A.And (equal e v, acc))
  in
  match CCList.mapi term cols with
  | [] -> None
  | t :: ts -> Some (CCListLabels.fold_left ~init:t ~f:(fun acc t -> A.Or (acc, t)) ts)

(* Resolve one ORDER BY entry to [(expr, cursor_value, dir, is_aggregate)].
   [expr] is the SQL expression the keyset comparison runs against; the cursor
   value is keyed exactly as [mk_cursor] stored it.  [is_aggregate] marks
   count-star columns, which can only be compared in HAVING. *)
let order_col_term col_alias_to_expr expr_to_col_alias page (e, dir) =
  let module A = Mql_ast in
  let open CCResult.Infix in
  match e with
  | A.Identifier col -> (
      match String_map.find_opt col col_alias_to_expr with
      | Some (A.Count A.Star as expr) -> mk_page_value page col >>= fun v -> Ok (expr, v, dir, true)
      | Some expr -> mk_page_value page col >>= fun v -> Ok (expr, v, dir, false)
      | None -> mk_page_value page col >>= fun v -> Ok (A.Identifier col, v, dir, false))
  | A.Field_select (A.Identifier _table, col) as expr ->
      mk_page_value page col >>= fun v -> Ok (expr, v, dir, false)
  | A.Count A.Star as expr ->
      let key =
        match Col_expr_map.find_opt Col_expr.Count_star expr_to_col_alias with
        | Some alias -> alias
        | None -> "count"
      in
      mk_page_value page key >>= fun v -> Ok (expr, v, dir, true)
  | _ -> assert false

(* The keyset predicate over the whole ORDER BY tuple, plus whether any ordered
   column is an aggregate (which forces the predicate into HAVING). *)
let mk_keyset_cond col_alias_to_expr expr_to_col_alias page order_by =
  let open CCResult.Infix in
  CCResult.map_l (order_col_term col_alias_to_expr expr_to_col_alias page) order_by
  >>= fun terms ->
  let has_aggregate = CCList.exists (fun (_, _, _, agg) -> agg) terms in
  let cols = CCList.map (fun (expr, value, dir, _) -> (expr, value, dir)) terms in
  Ok (lex_keyset page.Page.dir cols, has_aggregate)

let negate_dir = function
  | None | Some Mql_ast.Asc -> Some Mql_ast.Desc
  | Some Mql_ast.Desc -> Some Mql_ast.Asc

let apply_page_dir order_by = function
  | Page.Affirm -> order_by
  | Page.Negate -> CCList.map (fun (expr, dir) -> (expr, negate_dir dir)) order_by

let rec apply_page page t =
  let module A = Mql_ast in
  match t with
  | A.With { materialized; name; query; body } ->
      CCResult.map (fun body -> A.With { materialized; name; query; body }) (apply_page page body)
  | A.Query
      {
        body = A.Select ({ A.select_list; from = _; joins = _; where; group_by; having } as select);
        order_by = Some order_by;
        limit;
      } -> (
      let open CCResult.Infix in
      assert_order_by_cols_can_paginate order_by
      >>= fun () ->
      let col_alias_to_expr = col_alias_to_expr select_list in
      let expr_to_col_alias = expr_to_col_alias select_list in
      mk_keyset_cond col_alias_to_expr expr_to_col_alias page order_by
      >>= fun (keyset, has_aggregate) ->
      let order_by = apply_page_dir order_by page.Page.dir in
      match keyset with
      | None -> Ok (A.Query { body = A.Select select; order_by = Some order_by; limit })
      | Some keyset when has_aggregate -> (
          (* An aggregate in the ORDER BY forces the whole keyset into HAVING:
             WHERE cannot see aggregates, and a lexicographic OR-expansion cannot
             be split across the WHERE/HAVING boundary without reintroducing the
             flat-conjunction defect. *)
          match group_by with
          | None -> Error `Missing_group_by_err
          | Some _ ->
              let having =
                Some (CCOption.map_or ~default:keyset (fun having -> A.And (keyset, having)) having)
              in
              Ok
                (A.Query
                   { body = A.Select { select with A.having }; order_by = Some order_by; limit }))
      | Some keyset ->
          let where =
            Some (CCOption.map_or ~default:keyset (fun where -> A.And (keyset, where)) where)
          in
          Ok (A.Query { body = A.Select { select with A.where }; order_by = Some order_by; limit }))
  | A.Query { body = A.Select _; order_by = None; _ } -> Error `Missing_order_by_err
  (* Keyset pagination of a UNION / parenthesized query would need a derived table to
     hang the WHERE off of -- out of scope. *)
  | A.Query { body = A.Union _ | A.Paren _; _ } -> Error `Missing_order_by_err
