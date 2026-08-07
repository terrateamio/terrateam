(** Template-string parsing and AST post-processing.

    Split out from [Hcl_ast] so that file stays focused on parser plumbing (Menhir/Shim backends)
    and the pretty-printer. The functions here turn [Expr.String] values that actually contain
    [${...}] or [%{...}] into structured [Expr.Template] ASTs, apply the same promotion to
    [Obj_key.Quoted] object keys (lifting them to [Obj_key.Template] when their payload carries
    template syntax), and resolve the [$${] / [%%{] escape sequences inside plain literals on both
    sides.

    {1 Heredoc whitespace: two ordering rules}

    A [<<-] heredoc's common-indent strip and a template's [~] trim markers both remove whitespace,
    and both are applied here, while loading, so the parts an [Expr.Template_heredoc] carries are
    final and every later reader — evaluation, the printer, reference collection — sees the same
    value. Two things about that are load-bearing:

    - the strip runs AFTER the trim markers, over the parsed parts, never over the raw body. A [~]
      adjacent to a newline consumes that newline, so the whitespace opening the next source line
      stops being indentation and becomes ordinary mid-line text, which the strip must leave alone.
      Stripping the raw text first removes it and shortens the value. hclsyntax orders the two the
      same way;
    - each is applied exactly once. Neither is idempotent: the trim is line-scoped, so a second pass
      eats the following line, which is why the printer does not re-emit a [~] and does not re-emit
      the [-] of a [<<-].

    Neither divergence is visible in a stategraph-only plan/apply/plan cycle, which stays
    self-consistent whichever way the whitespace falls. They surface against state that tofu wrote
    from the original config, as an update whose two sides differ only in whitespace — so changes
    here are pinned against tofu rather than against reasoning: [flush_after_trim_markers] in
    [tests/sg_tf_eval], the trim-marker and heredoc cases in [tests/hcl_ast_to_string], and the
    [heredoc_flush_trim] e2e. *)

(** [contains_template_syntax s] is [true] iff [s] contains an unescaped [${...}] or [%{...}]
    introducer, i.e. template processing is needed. *)
val contains_template_syntax : string -> bool

(** [unescape_literal s] resolves template escape sequences in a literal string ([$${] -> [${],
    [%%{] -> [%{]); all other characters pass through unchanged. *)
val unescape_literal : string -> string

(** [escape_literal s] is the inverse of {!unescape_literal}: it re-introduces template escapes
    ([${] -> [$${], [%{] -> [%%{]) so a resolved literal string re-encodes to source form rather
    than being read back as an interpolation. Only template introducers are escaped. *)
val escape_literal : string -> string

(** The ways a template body can be malformed. Each corresponds to a pattern hclsyntax rejects.
    {!string_of_template_error} renders the matching shim/hclsyntax diagnostic phrasing. *)
type template_error =
  | Unclosed_interpolation
  | Unclosed_directive
  | Empty_directive
  | Invalid_interpolation_expression
  | Invalid_control_keyword
  | Extra_chars_in_else_marker
  | Unexpected_end_of_template
  | Unbalanced_directive of [ `Else | `Endif | `Endfor ]
  | Template_in_block_label of string

(** The shim/hclsyntax diagnostic phrasing for a {!template_error}. *)
val string_of_template_error : template_error -> string

(** Template parsing needs an expression parser for the content of each [${...}] and [%{if ...}] /
    [%{for ... in ...}] directive. The backend (Menhir/Shim) supplies it to [Make].

    Every exported function returns [Result.t] with a {!template_error} as its [Error] payload. *)
module Make (_ : sig
  val parse_expr_string : string -> Hcl_parser_value.Expr.t option
end) : sig
  (** Parse a string containing template syntax into a [Template_part.t list]; [Ok None] if the
      string contains no template syntax at all. Nested [Expr.String "${...}"] values inside
      interpolations are recursively transformed into [Expr.Template] so [escape_hcl_string] doesn't
      mangle them at print time. [Error err] when the template is malformed. *)
  val parse_template_string :
    string -> (Hcl_parser_value.Template_part.t list option, template_error) result

  (** Recursively walk an expression. Two transformations fire as the walk descends:

      - [Expr.String s] values whose payload contains template syntax become [Expr.Template parts];
        plain-literal payloads have their [$${] / [%%{] escapes resolved.
      - Inside [Expr.Object] pairs, [Obj_key.Quoted s] keys whose payload contains template syntax
        are promoted to [Obj_key.Template parts] (mirroring the [String -> Template] promotion);
        plain-literal [Obj_key.Quoted] payloads have their escapes resolved the same way.

      [Error err] when any walked string contains malformed template syntax. *)
  val transform_expr : Hcl_parser_value.Expr.t -> (Hcl_parser_value.Expr.t, template_error) result

  (** Walk an entire AST applying [transform_expr] to every contained expression. [Error err] on
      either kind of failure. *)
  val transform_ast : Hcl_parser_value.t list -> (Hcl_parser_value.t list, template_error) result

  (** Promote only [Heredoc]/[Heredoc'] nodes whose body carries template syntax to
      [Template_heredoc], leaving every other node untouched. For a backend whose parser leaves
      heredoc bodies raw but has already transformed [Expr.String] templates, where the full
      {!transform_ast} would double-process [$${] / [%%{] escapes. *)
  val promote_heredocs_ast :
    Hcl_parser_value.t list -> (Hcl_parser_value.t list, template_error) result
end
