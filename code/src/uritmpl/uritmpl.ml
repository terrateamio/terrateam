module Var = struct
  type v =
    | S of string
    | A of string list
    | M of (string * string) list

  type t = string * v
end

module Expandspec = struct
  type t = {
    kv : bool;
    sep : string;
    lead_char : char option;
    encode : string -> string;
  }
end

type varspec = {
  name : string;
  prefix : int option;
  explode : bool;
}

type expr =
  | Literal of string
  | Expr of {
      op : char option;
      vars : varspec list;
    }

type t = expr list
type parse_err = [ `Error ]

let rec exprs_of_tokens =
  let module T = Uritmpl_lexer.Token in
  function
  | [] -> []
  | T.Literal s :: ts -> Literal s :: exprs_of_tokens ts
  | T.Open_expr :: ts -> expr_of_tokens ts
  | _ -> assert false

and expr_of_tokens =
  let module T = Uritmpl_lexer.Token in
  function
  | T.Op op :: ts ->
      let vars, ts = vars_of_tokens [] ts in
      Expr { op = Some op; vars } :: exprs_of_tokens ts
  | ts ->
      let vars, ts = vars_of_tokens [] ts in
      Expr { op = None; vars } :: exprs_of_tokens ts

and vars_of_tokens acc =
  let module T = Uritmpl_lexer.Token in
  function
  | T.Close_expr :: ts -> (List.rev acc, ts)
  | T.Var_sep :: ts -> vars_of_tokens acc ts
  | T.Var name :: T.Prefix prefix :: T.Explode :: ts ->
      vars_of_tokens ({ name; prefix = Some prefix; explode = true } :: acc) ts
  | T.Var name :: T.Prefix prefix :: ts ->
      vars_of_tokens ({ name; prefix = Some prefix; explode = false } :: acc) ts
  | T.Var name :: T.Explode :: ts ->
      vars_of_tokens ({ name; prefix = None; explode = true } :: acc) ts
  | T.Var name :: ts -> vars_of_tokens ({ name; prefix = None; explode = false } :: acc) ts
  | _ -> assert false

let of_string s =
  match Uritmpl_lexer.tokenize s with
  | Ok tokens -> Ok (exprs_of_tokens tokens)
  | Error err -> Error `Error

let varspec_to_string buf vars =
  let strs =
    List.map
      (function
        | { name; prefix = Some n; explode = true } -> Printf.sprintf "%s:%d*" name n
        | { name; prefix = Some n; _ } -> Printf.sprintf "%s:%d" name n
        | { name; prefix = None; explode = true } -> name ^ "*"
        | { name; _ } -> name)
      vars
  in
  Buffer.add_string buf (String.concat "," strs)

let to_string t =
  let buf = Buffer.create 20 in
  List.iter
    (function
      | Literal s -> Buffer.add_string buf s
      | Expr { op = Some op; vars } ->
          Buffer.add_char buf '{';
          Buffer.add_char buf op;
          varspec_to_string buf vars;
          Buffer.add_char buf '}'
      | Expr { vars; _ } ->
          Buffer.add_char buf '{';
          varspec_to_string buf vars;
          Buffer.add_char buf '}')
    t;
  Buffer.contents buf

let expand_value spec v value =
  let open Expandspec in
  match value with
  | Var.S s -> (
      match (spec, v) with
      | { kv = true; encode; _ }, { name; prefix = Some prefix; _ } ->
          Printf.sprintf "%s=%s" name (encode (String.sub s 0 (min prefix (String.length s))))
      | { kv = false; encode; _ }, { name; prefix = Some prefix; _ } ->
          encode (String.sub s 0 (min prefix (String.length s)))
      | { kv = true; encode; lead_char; _ }, { name; _ } -> (
          match lead_char with
          | Some ';' when s = "" -> name
          | _ -> Printf.sprintf "%s=%s" name (encode s))
      | { kv = false; encode; _ }, _ -> encode s)
  | Var.A l -> (
      match (spec, v) with
      | { kv = true; encode; _ }, { name; explode = false; _ } ->
          Printf.sprintf "%s=%s" name (String.concat "," (List.map encode l))
      | { kv = true; encode; sep; lead_char; _ }, { name; explode = true; _ } ->
          String.concat sep (List.map (fun v -> Printf.sprintf "%s=%s" name (encode v)) l)
      | { kv = false; encode; _ }, { name; explode = false; _ } ->
          String.concat "," (List.map encode l)
      | { kv = false; encode; sep; _ }, { name; explode = true; _ } ->
          String.concat sep (List.map encode l))
  | Var.M m -> (
      match (spec, v) with
      | { kv = true; encode; _ }, { name; explode = false; _ } ->
          Printf.sprintf
            "%s=%s"
            name
            (String.concat "," (List.map (fun (k, v) -> encode k ^ "," ^ encode v) m))
      | { kv = true; encode; sep; _ }, { name; explode = true; _ } ->
          String.concat sep (List.map (fun (k, v) -> encode k ^ "=" ^ encode v) m)
      | { kv = false; encode; _ }, { name; explode = false; _ } ->
          String.concat "," (List.map (fun (k, v) -> encode k ^ "," ^ encode v) m)
      | { kv = false; encode; sep; _ }, { name; explode = true; _ } ->
          String.concat sep (List.map (fun (k, v) -> encode k ^ "=" ^ encode v) m))

let expand_var spec vars v =
  match List.assoc_opt v.name vars with
  | Some (Var.M []) -> None
  | Some value -> Some (expand_value spec v value)
  | None -> None

let expand t vars =
  let buf = Buffer.create 20 in
  List.iter
    (function
      | Literal s -> Buffer.add_string buf s
      | Expr { op; vars = vs } -> (
          let expand_spec =
            match op with
            | None ->
                Expandspec.
                  {
                    kv = false;
                    sep = ",";
                    lead_char = None;
                    encode = (fun s -> Uri.pct_encode ~component:`Authority s);
                  }
            | Some '+' ->
                Expandspec.
                  {
                    kv = false;
                    sep = ",";
                    lead_char = None;
                    encode =
                      (fun s ->
                        Uri.pct_encode ~component:(`Custom (`Path, ":/?#[]@!$&'()*+,;=", "")) s);
                  }
            | Some '#' ->
                Expandspec.
                  {
                    kv = false;
                    sep = ",";
                    lead_char = Some '#';
                    encode = (fun s -> Uri.pct_encode ~component:(`Custom (`Fragment, ";", "")) s);
                  }
            | Some '.' ->
                Expandspec.
                  {
                    kv = false;
                    sep = ".";
                    lead_char = Some '.';
                    encode = (fun s -> Uri.pct_encode ~component:`Authority s);
                  }
            | Some '/' ->
                Expandspec.
                  {
                    kv = false;
                    sep = "/";
                    lead_char = Some '/';
                    encode = (fun s -> Uri.pct_encode ~component:`Authority s);
                  }
            | Some ';' ->
                Expandspec.
                  {
                    kv = true;
                    sep = ";";
                    lead_char = Some ';';
                    encode = (fun s -> Uri.pct_encode ~component:`Authority s);
                  }
            | Some '?' ->
                Expandspec.
                  {
                    kv = true;
                    sep = "&";
                    lead_char = Some '?';
                    encode = (fun s -> Uri.pct_encode ~component:`Query_value s);
                  }
            | Some '&' ->
                Expandspec.
                  {
                    kv = true;
                    sep = "&";
                    lead_char = Some '&';
                    encode = (fun s -> Uri.pct_encode ~component:`Query_value s);
                  }
            | _ -> assert false
          in
          let res =
            vs
            |> List.map (fun v ->
                   match expand_var expand_spec vars v with
                   | Some r -> [ r ]
                   | None -> [])
            |> List.flatten
          in
          match res with
          | [] -> ()
          | r ->
              let s = String.concat expand_spec.Expandspec.sep r in
              let lead =
                Option.value
                  (Option.map (String.make 1) expand_spec.Expandspec.lead_char)
                  ~default:""
              in
              Buffer.add_string buf lead;
              Buffer.add_string buf s))
    t;
  Buffer.contents buf
