type err = [ `Hcl_native_error of string ] [@@deriving show]

(** [parse_string src] parses an HCL source string using hashicorp/hcl/v2's native parser via the
    [sg_hcl_shim] subprocess, and returns the resulting top-level items in the same shape as the
    hand-written Menhir parser.

    The shim is spawned lazily on first use and reused across subsequent calls; it lives for the
    lifetime of the OCaml process. If the shim dies unexpectedly (e.g. killed externally), the next
    call transparently respawns it.

    The shim binary is expected to exist as a sibling of the current executable, at
    [../hcl_native_shim/sg_hcl_shim]. That path is populated by the shim's Makefile in development
    and test environments. Production builds don't ship the shim; production code must not call this
    module — use [Hcl_ast.of_string] (Menhir) instead. [Hcl_native] is called directly only from
    test code that needs to exercise the shim explicitly. If the sibling binary is missing or fails
    to spawn, all parse entry points return [`Hcl_native_error]. *)
val parse_string : string -> (Hcl_parser_value.t list, [> err ]) result

(** [parse_expr_string src] parses a standalone HCL expression (what appears inside [${...}]
    interpolations). Uses the same shim subprocess as {!parse_string}. *)
val parse_expr_string : string -> (Hcl_parser_value.Expr.t, [> err ]) result

(** [parse_template_string src] parses template source — the unquoted content between the quotes of
    an HCL string, including [${...}] interpolations and [%{...}] directives. Returns the sequence
    of template parts. *)
val parse_template_string : string -> (Hcl_parser_value.Template_part.t list, [> err ]) result
