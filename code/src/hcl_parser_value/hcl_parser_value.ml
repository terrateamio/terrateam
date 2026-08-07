module Block_label = struct
  type t =
    | Id of string
    | Lit of string
  [@@deriving show { with_path = false }, eq, ord, yojson]

  (** Function for when one wants to identify the two kind of labels *)
  let to_string = function
    | Id s -> s
    | Lit s -> s
end

module Attr = struct
  type t =
    | A_string of string
    | A_int of int
    | A_splat
  [@@deriving show { with_path = false }, eq, ord, yojson]
end

module rec Template_part : sig
  type t =
    | Literal of string
    | Interpolation of {
        expr : Expr.t;
        strip_before : bool;
        strip_after : bool;
      }
    | If_directive of {
        cond : Expr.t;
        then_ : t list;
        else_ : t list option;
        strip_before : bool;
        strip_after : bool;
      }
    | For_directive of {
        vars : string * string option; (* value, optional key *)
        input : Expr.t;
        body : t list;
        strip_before : bool;
        strip_after : bool;
      }
  [@@deriving show { with_path = false }, eq, ord, yojson]
end = struct
  type t =
    | Literal of string
    | Interpolation of {
        expr : Expr.t;
        strip_before : bool;
        strip_after : bool;
      }
    | If_directive of {
        cond : Expr.t;
        then_ : t list;
        else_ : t list option;
        strip_before : bool;
        strip_after : bool;
      }
    | For_directive of {
        vars : string * string option;
        input : Expr.t;
        body : t list;
        strip_before : bool;
        strip_after : bool;
      }
  [@@deriving show { with_path = false }, eq, ord, yojson]
end

and Obj_key : sig
  (* Keys of [Expr.Object] entries, preserving the syntactic form they
     parsed from. The five constructors mirror the surface forms in the
     HCL spec
     (https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md#collection-values):

     - [Bare s] — bareword identifier or numeric literal: [{foo = 1}],
       [{007 = 1}], [{true = 1}]. Printed without quotes.
     - [Quoted s] — quoted literal string with no template syntax:
       [{"foo" = 1}]. Printed with surrounding double quotes.
     - [Template parts] — quoted string containing [${...}] / [%{...}]
       template syntax: [{"${var.x}" = 1}]. Printed with surrounding
       double quotes; per the HCL spec the value evaluates the template
       and uses the resulting string as the key.
     - [Computed e] — a parenthesized expression: [{(var.x) = 1}].
       Printed with surrounding parens; per the HCL spec the parens
       force key evaluation rather than literal interpretation.
     - [Expr e] — a non-parenthesized compound expression admitted by
       the lenient hclsyntax grammar: [{foo.bar = 1}], [{a + b = 1}],
       [{foo(x) = 1}]. Printed without parens or quotes. Strict spec
       compliance would require wrapping these in parens; we follow
       hclsyntax's lenience. *)
  type t =
    | Bare of string
    | Quoted of string
    | Template of Template_part.t list
    | Computed of Expr.t
    | Expr of Expr.t
  [@@deriving show { with_path = false }, eq, ord, yojson]
end = struct
  type t =
    | Bare of string
    | Quoted of string
    | Template of Template_part.t list
    | Computed of Expr.t
    | Expr of Expr.t
  [@@deriving show { with_path = false }, eq, ord, yojson]
end

and Expr : sig
  type t =
    | Id of string
    | String of string
    | Template of Template_part.t list
    | Int of int
    | Float of float
    | Bool of bool
    | Null
    | Tuple of t list
    | Object of (Obj_key.t * t) list
    | Fun_call of (string * t list)
    | For_tuple of {
        identifiers : string * string list;
        input : t;
        output : t;
        cond : t option;
      }
    | For_object of {
        identifiers : string * string list;
        input : t;
        key_output : t;
        value_output : t;
        cond : t option;
      }
    | Cond of {
        if_ : t;
        then_ : t;
        else_ : t;
      }
    | Idx of (t * t)
    | Attr of (t * Attr.t)
    | Splat
    | Not of t
    | Minus of t
    | Add of (t * t)
    | Subtract of (t * t)
    | Mult of (t * t)
    | Div of (t * t)
    | Log_and of (t * t)
    | Log_or of (t * t)
    | Equal of (t * t)
    | Not_equal of (t * t)
    | Gt of (t * t)
    | Lt of (t * t)
    | Gte of (t * t)
    | Lte of (t * t)
    | Mod of (t * t)
    | Heredoc of (string * string)
    | Heredoc' of (string * string)
    | Template_heredoc of (string * Template_part.t list)
        (** A heredoc whose body carries [${...}] / [%{...}] template syntax, promoted from
            [Heredoc] at load time (see {!Hcl_ast_template}) so references and interpolations are
            structured rather than buried in a raw string. The [string] is the heredoc marker. *)
    | Ellipsis of t
  [@@deriving show { with_path = false }, eq, ord, yojson]
end = struct
  type t =
    | Id of string
    | String of string
    | Template of Template_part.t list
    | Int of int
    | Float of float
    | Bool of bool
    | Null
    | Tuple of t list
    | Object of (Obj_key.t * t) list
    | Fun_call of (string * t list)
    | For_tuple of {
        identifiers : string * string list;
        input : t;
        output : t;
        cond : t option;
      }
    | For_object of {
        identifiers : string * string list;
        input : t;
        key_output : t;
        value_output : t;
        cond : t option;
      }
    | Cond of {
        if_ : t;
        then_ : t;
        else_ : t;
      }
    | Idx of (t * t)
    | Attr of (t * Attr.t)
    | Splat
    | Not of t
    | Minus of t
    | Add of (t * t)
    | Subtract of (t * t)
    | Mult of (t * t)
    | Div of (t * t)
    | Log_and of (t * t)
    | Log_or of (t * t)
    | Equal of (t * t)
    | Not_equal of (t * t)
    | Gt of (t * t)
    | Lt of (t * t)
    | Gte of (t * t)
    | Lte of (t * t)
    | Mod of (t * t)
    | Heredoc of (string * string)
    | Heredoc' of (string * string)
    | Template_heredoc of (string * Template_part.t list)
        (** A heredoc whose body carries [${...}] / [%{...}] template syntax, promoted from
            [Heredoc] at load time (see {!Hcl_ast_template}) so references and interpolations are
            structured rather than buried in a raw string. The [string] is the heredoc marker. *)
    | Ellipsis of t
  [@@deriving show { with_path = false }, eq, ord, yojson]
end

type t =
  | Block of {
      type_ : string;
      labels : Block_label.t list;
      body : t list;
    }
  | Attribute of string * Expr.t
[@@deriving show { with_path = false }, eq, ord, yojson]

module Number = struct
  (* Shortest decimal that reads back as the same float, which is what both writers of an
     [Expr.Float] need: the HCL printer, whose output is re-parsed (by us and by tofu), and the
     cty-compatible JSON encoder.

     OCaml's [string_of_float] is unusable for either. It caps at 12 significant digits, so
     [3.141592653589793] comes back as [3.14159265359] — a silently different number in every
     rendered config, and a spurious plan diff on any float attribute carrying more precision than
     that. It also renders integral and underflowed values with a bare trailing dot ([1.], [0.]),
     which is not a valid HCL number at all: the reader takes the dot as attribute access and the
     file fails to load.

     Integral values print without a fraction ([1], not [1.0]) because HCL has a single number type,
     so the two are the same value; above [1e16] a float can no longer represent every integer and
     [%.0f] would print a spuriously exact digit string, so those go through the shortest-form search
     and may come out in exponent notation, which HCL accepts. *)
  let shortest_float f =
    if Float.is_integer f && Float.abs f < 1e16 then Printf.sprintf "%.0f" f
    else
      let rec shortest p =
        if p > 17 then Printf.sprintf "%.17g" f
        else
          let s = Printf.sprintf "%.*g" p f in
          if Float.equal (float_of_string s) f then s else shortest (p + 1)
      in
      shortest 1
end
