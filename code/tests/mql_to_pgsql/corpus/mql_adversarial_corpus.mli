(** The adversarial MQL queries of RFD 1724.

    The unit tests of [mql_to_pgsql] and the integration tests of the MQL endpoint must run the same
    queries, thus the queries live here and not in one of the two test binaries. All queries read
    the tables of the MQL endpoint schema. *)

(** Named templates that put an expression in each position the RFD lists: select list, [WHERE],
    [JOIN ... ON], [ORDER BY], [LIMIT], subquery, CTE body, each branch of a set operation, [CASE],
    array constructor, and argument of an allowed function. The name is for failure messages. *)
val positions : (string * (string -> string)) list

(** Functions that read a table, a column or a setting by a name in a value, or that reach outside
    the database. Each entry is the function name and one call expression. None of them is in the
    default allow list, thus each call must give [`Func_access_err]. *)
val forbidden_functions : (string * string) list

(** Cast targets that name a database object. Each entry is the type name and one cast expression.
    None of them is in the default cast allow list, thus each cast must give [`Cast_err]. *)
val forbidden_casts : (string * string) list

(** Whole queries that try to get around the name checks: case, quoting, Unicode escapes, comments
    in qualified names, [OPERATOR(...)], [TABLE], [ONLY], [ROWS FROM] and function calls in [FROM].
    Each entry is a description and the query. Each query must give an error. *)
val name_tricks : (string * string) list

(** A fixed copy of the default function allow list of [mql_to_pgsql]. A test compares it to the
    list of the library, thus a change to the library list fails that test until the change is
    reviewed here. *)
val default_func_allow_list : string list

(** A fixed copy of the default cast allow list of [mql_to_pgsql], for the same reason as
    {!default_func_allow_list}. *)
val default_cast_allow_list : string list

(** For each function of {!default_func_allow_list}, queries that call it with a table name, a
    column name or a SQL statement as a text argument. A test makes sure that the keys are equal to
    {!default_func_allow_list}, thus a new function in the allow list has no adversarial test until
    one is added here. *)
val allowed_function_cases : (string * string list) list

(** Each query of {!forbidden_functions} and {!forbidden_casts} in each of {!positions}, then each
    query of {!name_tricks} and of {!allowed_function_cases}. Each entry is a description and the
    query. *)
val all_queries : unit -> (string * string) list

(** The queries of {!all_queries} that {!refused} must hold for: the forbidden functions and casts
    in each position, then the name tricks. The allowed-function queries are not here, because
    accepting them is the point. *)
val refusal_queries : unit -> (string * string) list

(** What happens to one query of the corpus: MQL cannot read it, {!Mql_to_pgsql.of_mql} refuses it,
    or [of_mql] accepts it. The refusal rules -- which errors are a refusal, and which are the audit
    finding a guard that did not fire -- live here, so the unit suite of [mql_to_pgsql] and the
    tests of the MQL endpoint cannot drift apart. *)
type outcome =
  | Parse_err of Mql.Ast.err
  | Of_mql_err of Mql_to_pgsql.err
  | Accepted

val show_outcome : outcome -> string

(** [outcome ?variables ?schema query] reads [query] and puts it through {!Mql_to_pgsql.of_mql} with
    the default allow lists. [variables] is [false] by default, the posture of the endpoint; the
    unit suite of [mql_to_pgsql] reads [true], which its queries need for their [$name] variables.
*)
val outcome : ?variables:bool -> ?schema:Mql_to_pgsql.Schema.t -> string -> outcome

(** [accepted o] holds when the query went through. *)
val accepted : outcome -> bool

(** [refused o] holds when the query is refused at parse or by a guard of the rewrite. An audit
    error is not a refusal: the audit finds only what a guard did not refuse, thus in a test it
    shows a missing guard, and a test must not count it as an ordinary rejection. *)
val refused : outcome -> bool

(** Each classifier holds when the outcome is the one its name says. *)
val of_mql_err : Mql_to_pgsql.err -> outcome -> bool

val func_access_err : outcome -> bool
val cast_err : outcome -> bool
val unknown_column_err : outcome -> bool
val construct_not_allowed_err : outcome -> bool
