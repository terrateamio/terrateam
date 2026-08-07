(** Normalize the HCL AST for equality/hashing consumers (e.g. revision comparison): rewrite
    constructs whose surface form can vary but whose meaning to OpenTofu does not, so two
    semantically-equal inputs converge to one AST.

    Normalized: object/map key order (stable sort on the evaluated key, last-wins preserved), the
    [Bare]/[Quoted] object-key distinction (folded to [Quoted]), body item order (attributes sorted
    by name and hoisted above child blocks, which keep their relative order), and the [Id]/[Lit]
    block-label distinction (folded to [Lit]).

    {b Not} normalized: [Tuple] element order. A HCL [[...]] parses to [Tuple] whether it is an
    ordered list or an (order-insensitive) set, and the AST carries no type information to tell them
    apart, so sorting would corrupt genuine lists.

    Re-exposed as [Hcl_ast.Normalize], which is how callers should reach these functions.

    {2 Examples}

    Every example below is the exact [Hcl_ast.To_string.ast (ast (parse …))] output, pinned by
    [normalize_doc_examples] in [code/tests/hcl_ast/test.ml] — an example that drifts from what
    {!ast} produces fails the test rather than quietly misinforming.

    Object keys sort by evaluated key string, and the [Bare]/[Quoted] distinction folds to [Quoted]:
    {v
    x = { b = 1, "a" = 2 }
      -> x = {
        "a" = 2
        "b" = 1
      }
    v}

    A numeric bareword key is the number it evaluates to, so [007] becomes the key ["7"] (whereas
    the quoted ["007"] is a distinct literal-string key and is left as-is):
    {v
    x = { 007 = 1 }
      -> x = {
        "7" = 1
      }
    v}

    Within a block body, attributes sort by name and hoist above child blocks; the block label folds
    [Id] to [Lit] ([aws_x] -> ["aws_x"]); repeated child blocks keep their source order:
    {v
    resource aws_x "y" {
      z = 3
      provisioner "b" {}
      a = 1
      provisioner "a" {}
    }
      -> resource "aws_x" "y" {
        a = 1
        z = 3

        provisioner "b" {
        }

        provisioner "a" {
        }
      }
    v} *)

(** Splice nested single-template interpolations into the parent's part list: [${"${X}"}] -> [${X}].
    Recurses through [Template]/[Fun_call]/[Tuple]/[Object]; a wrapper buried inside a
    [Cond]/[Idx]/operator arm is left as-is. Callable on its own, and applied by the entry points
    below when [~normalize_templates:true].

    Every example below is the exact [Hcl_ast.To_string.expr (template (parse …))] output, pinned by
    [template_doc_examples] in [code/tests/hcl_ast/test.ml].

    The core case — an interpolation whose whole body is another template unwraps to that template:
    {v "${"${foo}"}"        -> "${foo}" v}

    The spliced interpolation need not be the only part, and the inner template may itself have
    several parts — all of them inline into the parent:
    {v
    "${a}${"${b}"}c"     -> "${a}${b}c"
    "${"${foo}bar"}"     -> "${foo}bar"
    v}

    It recurses into function-call arguments, tuple elements, and object values:
    {v
    upper("${"${foo}"}")           -> upper("${foo}")
    ["${"${a}"}", "${"${b}"}"]     -> ["${a}", "${b}"]
    v}

    But a wrapper buried inside a [Cond] (or [Idx]/operator) arm is left untouched — here the
    conditional arm keeps its wrapped [${"${a}"}] (the surrounding parentheses are just how
    {!Hcl_ast.To_string} prints a conditional):
    {v foo ? "${"${a}"}" : b          -> (foo ? "${"${a}"}" : b) v} *)
val template : Hcl_parser_value.Expr.t -> Hcl_parser_value.Expr.t

(** Normalize a single expression (recursively). With [~normalize_templates:true] (default [false]),
    also applies {!template} to flatten wrapped single-template interpolations. *)
val expr : ?normalize_templates:bool -> Hcl_parser_value.Expr.t -> Hcl_parser_value.Expr.t

(** Normalize a single top-level item (attribute or block, recursively). With
    [~normalize_templates:true] (default [false]), also applies {!template} to each contained
    attribute expression. *)
val value : ?normalize_templates:bool -> Hcl_parser_value.t -> Hcl_parser_value.t

(** Normalize a whole AST ([value] over each top-level item). With [~normalize_templates:true]
    (default [false]), also applies {!template} to each contained attribute expression. *)
val ast : ?normalize_templates:bool -> Hcl_parser_value.t list -> Hcl_parser_value.t list
