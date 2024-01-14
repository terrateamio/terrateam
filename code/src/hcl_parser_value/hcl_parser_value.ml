module Block_label = struct
  type t =
    | Id of string
    | Lit of string
  [@@deriving show { with_path = false }, eq, yojson]
end

module Attr = struct
  type t =
    | A_string of string
    | A_int of int
    | A_splat
  [@@deriving show { with_path = false }, eq, yojson]
end

module Expr = struct
  type t =
    | Id of string
    | String of string
    | Int of int
    | Float of float
    | Bool of bool
    | Null
    | Tuple of t list
    | Object of (t * t) list
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
    | Gt of (t * t)
    | Lt of (t * t)
    | Gte of (t * t)
    | Lte of (t * t)
    | Mod of (t * t)
    | Heredoc of string
    | Heredoc' of string
  [@@deriving show { with_path = false }, eq, yojson]
end

type t =
  | Block of {
      type_ : string;
      labels : Block_label.t list;
      body : t list;
    }
  | Attribute of string * Expr.t
[@@deriving show { with_path = false }, eq, yojson]
