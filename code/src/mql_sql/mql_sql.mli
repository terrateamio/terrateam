(** Read the SQL of this repository with MQL, and write it again.

    A caller applies these functions where it binds the query text at module level. The read step
    then occurs when the module loads, thus a query that MQL cannot read stops the program at the
    start and not at the request that uses it.

    What the caller gives to PostgreSQL is the text that MQL writes, and not the text of the file.
    The migration streams do the same -- see [Sgs_migrations.read_stmts] -- but they report a
    failure as an error, because a migration runs long after the module loads. *)

(** MQL cannot read the text, or cannot write the tree again. The message names the fault, gives the
    position, and gives the text. *)
exception Sql_err of string

(** Read one statement and write it again. The written text is read back once more and must give the
    same tree -- render parity, the same rule the corpus gate applies to the .sql files. Raise
    {!Sql_err} on a fault, of the reader or of the writer. *)
val read : string -> string

(** Read one or more statements, separated by [;], and write each one. The parser decides where each
    statement ends, thus a [;] inside a string literal is not a boundary. Each written statement is
    read back, as in {!read}. Raise {!Sql_err} on a fault. *)
val read_multi : string -> string list

(** [read_multi_result sql] is {!read_multi} as a result rather than an exception. The migration
    streams read each migration where the list of migrations is built, and one MQL cannot read must
    fail the run that applies it, not the program that loads the list -- see the read of the
    [;]-separated statements in [Sgs_migrations] and [Terrat_migrations]. The migration files name
    no [$name] variable, so they read with [~variables:false], which refuses one early rather than
    letting it reach [Pgsql_io.Typed_sql] as a parameter. *)
val read_multi_result : ?variables:bool -> string -> (string list, [> Mql.Ast.err ]) result

(** [set ~name value] writes [set name = 'value'], and [~local:true] writes [set local ...].

    PostgreSQL does not accept a prepared-statement parameter in a [SET] statement, thus the value
    must go in the text. This builds the MQL tree and writes it, thus MQL makes the value a string
    literal and escapes it; a [Printf.sprintf] does not. The name goes into the text unquoted, so it
    must be a legal unquoted identifier -- letters, digits, underscore, no leading digit -- and
    {!Sql_err} names anything else.

    Raise {!Sql_err} if the name is not a legal identifier, or if MQL cannot write the tree, which
    is a defect of the writer and not of the caller. *)
val set : ?local:bool -> name:string -> string -> string

(** Read one statement into a tree. Use this for a query that gets a part at run time: the [.sql]
    file holds a [$name] variable in that place, thus MQL reads the whole file when the module
    loads. Raise {!Sql_err} on a fault. *)
val read_ast : string -> Mql.Ast.t

(** Write a tree that the program built. Use this where the shape of the statement comes from data
    and not from a file, thus no text of it exists to read. *)
val write : Mql.Ast.t -> (string, [> Mql.Ast.err ]) result

(** [write_exn ast] writes a statement that the builder made, as one string. Raise {!Sql_err} if the
    writer cannot write the tree, which is a defect of the writer and not of the caller -- the same
    as {!set}. Use this where the statement is bound at module level, where a result has nobody to
    give itself to. *)
val write_exn : Mql.Ast.t -> string

(** [subst_var ~name expr q] puts [expr] in the place of each [$name] variable of [q].

    The [.sql] file holds the variable, thus MQL reads the whole file when the module loads. The
    part that the program builds arrives at the request and takes the place of the variable.

    Fail if the query holds no such variable, which means the file no longer has the shape this
    expects. *)
val subst_var : name:string -> Mql_ast.expr -> Mql.Ast.t -> (Mql.Ast.t, [> Mql.Ast.err ]) result

(** [subst_cte ~name query q] puts [query] in the place of the body of the CTE that [name] names.

    A CTE body is a query and not an expression, thus a [$name] variable cannot hold its place. The
    [.sql] file writes a placeholder query there, and this puts the real one in its place.

    Fail if the query has no CTE of that name. *)
val subst_cte : name:string -> Mql.Ast.t -> Mql.Ast.t -> (Mql.Ast.t, [> Mql.Ast.err ]) result

(** [with_where ~name q where] reads the filter [where] as an expression, puts it in the place of
    the [$name] variable of [q], and writes the query. An empty filter becomes [true].

    The filter arrives at the request, as text that another module builds, thus it is read here and
    not built as a tree. Give it text from this codebase only. *)
val with_where : name:string -> Mql.Ast.t -> string -> (string, [> Mql.Ast.err ]) result
