module Token = struct
  type token =
    | Literal    of string
    | Open_expr
    | Close_expr
    | Op         of char
    | Var        of string
    | Prefix     of int
    | Explode
    | Var_sep
  [@@deriving show, eq]

  type t = token list [@@deriving show, eq]
end

module Tb : sig
  type t

  val create : unit -> t

  val add : Token.token -> t -> t

  val build : t -> Token.t
end = struct
  type t = Token.t

  let create () = []

  let add v t = v :: t

  let build t = List.rev t
end

type err =
  [ `Premature_end
  | `Error
  | `Invalid_prefix
  ]
[@@deriving show, eq]

open Token

let rec token bldr buf =
  match%sedlex buf with
    | "{"                   -> expr (Tb.add Open_expr bldr) buf
    | Star (Sub (any, "{")) ->
        let str = Sedlexing.Utf8.lexeme buf in
        token (Tb.add (Literal str) bldr) buf
    | eof                   -> Ok (Tb.build bldr)
    | _                     -> assert false

and expr bldr buf =
  match%sedlex buf with
    | Chars "+#./;?&" ->
        let op = Sedlexing.Utf8.lexeme buf in
        variable (Tb.add (Op op.[0]) bldr) buf
    | eof             -> Error `Premature_end
    | _               ->
        Sedlexing.rollback buf;
        variable bldr buf

and variable bldr buf =
  match%sedlex buf with
    | Star (Sub (any, Chars "-:*,}")) ->
        let name = Sedlexing.Utf8.lexeme buf in
        varspec (Tb.add (Var name) bldr) buf
    | _                               -> assert false

and varspec bldr buf =
  match%sedlex buf with
    | ':' -> prefix bldr buf
    | '*' -> maybe_next_var (Tb.add Explode bldr) buf
    | _   ->
        Sedlexing.rollback buf;
        maybe_next_var bldr buf

and prefix bldr buf =
  match%sedlex buf with
    | Plus '0' .. '9' ->
        let len = int_of_string (Sedlexing.Utf8.lexeme buf) in
        maybe_next_var (Tb.add (Prefix len) bldr) buf
    | _               -> Error `Invalid_prefix

and maybe_explode bldr buf =
  match%sedlex buf with
    | '*' -> maybe_next_var (Tb.add Explode bldr) buf
    | ',' -> variable (Tb.add Var_sep bldr) buf
    | '}' -> token (Tb.add Close_expr bldr) buf
    | _   -> Error `Error

and maybe_next_var bldr buf =
  match%sedlex buf with
    | ',' -> variable (Tb.add Var_sep bldr) buf
    | '}' -> token (Tb.add Close_expr bldr) buf
    | _   -> Error `Error

let tokenize s = token (Tb.create ()) (Sedlexing.Utf8.from_string s)
