module Kv = struct
  module Map = CCMap.Make (String)

  type scalar =
    | I of int
    | F of float
    | S of string
    | B of bool
  [@@deriving show, eq]

  type t =
    | V of scalar
    | L of t Map.t list [@printer CCList.pp (Map.pp CCString.pp pp)]
  [@@deriving show, eq]

  let list m = L m
  let int i = V (I i)
  let float f = V (F f)
  let string s = V (S s)
  let bool b = V (B b)

  let to_string = function
    | I v -> CCInt.to_string v
    | F v -> CCFloat.to_string v
    | S v -> v
    | B v -> Bool.to_string v
end

module Transformer = struct
  type t = string * (Kv.scalar -> Kv.scalar)
end

module Template = struct
  type err =
    [ `Exn of (exn[@printer fun fmt exn -> fprintf fmt "%s" (Printexc.to_string exn)])
    | Snabela_lexer.err
    ]
  [@@deriving show]

  type t = Snabela_lexer.Token.t

  let is_space = function
    | ' ' | '\012' | '\r' | '\t' -> true
    | _ -> false

  let trim_trailing_ws s =
    if s = "" then s
    else
      let i = ref (String.length s - 1) in
      while !i >= 0 && is_space s.[!i] do
        i := !i - 1
      done;
      StringLabels.sub s ~pos:0 ~len:(!i + 1)

  let trim_leading_ws s =
    if s = "" then s
    else
      let i = ref 0 in
      while !i < String.length s && is_space s.[!i] do
        i := !i + 1
      done;
      if !i < String.length s && s.[!i] = '\n' then i := !i + 1;
      StringLabels.sub s ~pos:!i ~len:(CCString.length s - !i)

  let apply_trims tokens =
    let open Snabela_lexer.Token in
    let rec at acc = function
      | String s :: At ln :: Left_trim :: xs ->
          (* @-... *)
          at (At ln :: String (trim_trailing_ws s) :: acc) xs
      | At ln :: Left_trim :: xs ->
          (* Left trim is the first thing *)
          at (At ln :: acc) xs
      | Right_trim :: At ln :: String s :: xs ->
          (* ... -@ ... *)
          at (At ln :: acc) (String (trim_leading_ws s) :: xs)
      | Right_trim :: At ln :: xs ->
          (* ... -@ ... *)
          at (At ln :: acc) xs
      | x :: xs -> at (x :: acc) xs
      | [] -> acc
    in
    List.rev (at [] tokens)

  let remove_comments tokens =
    let open Snabela_lexer.Token in
    let rec rc acc = function
      | At _ :: Comment :: At _ :: xs -> rc acc xs
      | x :: xs -> rc (x :: acc) xs
      | [] -> acc
    in
    List.rev (rc [] tokens)

  let of_utf8_string s =
    let open CCResult.Infix in
    try
      let lexbuf = Sedlexing.Utf8.from_string s in
      Snabela_lexer.tokenize lexbuf >>= fun tokens -> Ok (remove_comments (apply_trims tokens))
    with exn -> Error (`Exn exn)
end

module TMap = CCMap.Make (String)

type line_number = int [@@deriving show]

type err =
  [ `Missing_key of string * line_number
  | `Expected_boolean of string * line_number
  | `Expected_list of string * line_number
  | `Missing_transformer of string * line_number
  | `Non_scalar_key of string * line_number
  | `Premature_eof
  | `Missing_closing_section of string
  ]
[@@deriving show]

exception Apply_error of err

type trans_func = Kv.scalar -> Kv.scalar

type t = {
  template : Template.t;
  transformers : trans_func TMap.t;
  append_transformers : trans_func list;
}

let of_template ?(append_transformers = []) t tr =
  let transformers = TMap.of_list tr in
  { template = t; transformers; append_transformers }

let string_of_scalar = function
  | Kv.I i -> Printf.sprintf "%d" i
  | Kv.F f -> Printf.sprintf "%f" f
  | Kv.S s -> s
  | Kv.B true -> "true"
  | Kv.B false -> "false"

let rec skip_section key =
  let open Snabela_lexer.Token in
  function
  | At _ :: List :: Key k :: At _ :: ts
  | At _ :: List :: Test :: Key k :: At _ :: ts
  | At _ :: List :: Neg_test :: Key k :: At _ :: ts
  | At _ :: Test :: Key k :: At _ :: ts
  | At _ :: Neg_test :: Key k :: At _ :: ts -> skip_section key (skip_section k ts)
  | At _ :: End_section :: Key k :: At _ :: ts when key = k ->
      (* @/key@ *)
      ts
  | [] -> raise (Apply_error (`Missing_closing_section key))
  | _ :: ts -> skip_section key ts

let apply_transformers v trs = ListLabels.fold_left ~f:(fun v f -> f v) ~init:v trs

let rec eval_template buf t kv template section =
  let open Snabela_lexer.Token in
  match template with
  | [] when section = "" -> []
  | [] when section <> "" -> raise (Apply_error (`Missing_closing_section section))
  | [] -> raise (Apply_error `Premature_eof)
  | Escaped_at :: ts ->
      (* @@ *)
      Buffer.add_char buf '@';
      eval_template buf t kv ts section
  | String s :: ts ->
      (* Foo *)
      Buffer.add_string buf s;
      eval_template buf t kv ts section
  | At ln :: Key k :: ts ->
      (* @key [ | t1 | t2 ... ] @ *)
      let t_test = function
        | Snabela_lexer.Token.Transformer _ -> true
        | _ -> false
      in
      let t_map = function
        | Snabela_lexer.Token.Transformer name -> (
            match TMap.get name t.transformers with
            | Some f -> f
            | None -> raise (Apply_error (`Missing_transformer (name, ln))))
        | _ -> assert false
      in
      let trans = CCList.take_while t_test ts in
      let ts = CCList.drop (List.length trans + 1) ts in
      let v =
        match Kv.Map.get k kv with
        | Some (Kv.V v) -> (
            match v with
            | (Kv.I _ | Kv.F _ | Kv.S _ | Kv.B _) as scalar -> scalar)
        | Some (Kv.L _) -> raise (Apply_error (`Non_scalar_key (k, ln)))
        | None -> raise (Apply_error (`Missing_key (k, ln)))
      in
      let transformed_k =
        apply_transformers
          (apply_transformers v (ListLabels.map ~f:t_map trans))
          t.append_transformers
      in
      Buffer.add_string buf (string_of_scalar transformed_k);
      eval_template buf t kv ts section
  | At ln :: Test :: Key k :: At _ :: ts ->
      (* @?key@ ... @/key@ *)
      eval_bool_section ln buf t kv ts section k true
  | At ln :: Neg_test :: Key k :: At _ :: ts ->
      (* @!key@ ... @/key@ *)
      eval_bool_section ln buf t kv ts section k false
  | At ln :: List :: Key k :: At _ :: ts ->
      (* @#key@ ... @/key@ *)
      eval_list_section ln buf t kv ts section k
  | At ln :: List :: Test :: Key k :: At _ :: ts ->
      (* @#?key@ ... @/key@ *)
      eval_list_test_section ln buf t kv ts section k `Not_empty
  | At ln :: List :: Neg_test :: Key k :: At _ :: ts ->
      (* @#!key@ ... @/key@ *)
      eval_list_test_section ln buf t kv ts section k `Empty
  | At ln :: Exists :: Test :: Key k :: At _ :: ts ->
      eval_exists_test_section ln buf t kv ts section k `Exists
  | At ln :: Exists :: Neg_test :: Key k :: At _ :: ts ->
      eval_exists_test_section ln buf t kv ts section k `Not_exists
  | At _ :: End_section :: Key k :: At _ :: ts when k = section ->
      (* @/key@ *)
      ts
  | _ -> assert false

and eval_bool_section ln buf t kv ts section key b =
  match CCString.Split.left ~by:"=" key with
  | None -> (
      match Kv.Map.get key kv with
      | Some (Kv.V (Kv.B v)) when v = b ->
          let ts = eval_template buf t kv ts key in
          eval_template buf t kv ts section
      | Some (Kv.V (Kv.B _)) ->
          let ts = skip_section key ts in
          eval_template buf t kv ts section
      | Some _ -> raise (Apply_error (`Expected_boolean (key, ln)))
      | None -> raise (Apply_error (`Missing_key (key, ln))))
  | Some (key', value) -> (
      match Kv.Map.get key' kv with
      | Some (Kv.V v) when CCString.equal (Kv.to_string v) value = b ->
          let ts = eval_template buf t kv ts key in
          eval_template buf t kv ts section
      | Some _ ->
          let ts = skip_section key ts in
          eval_template buf t kv ts section
      | None -> raise (Apply_error (`Missing_key (key, ln))))

and eval_list_section ln buf t kv ts section key =
  match Kv.Map.get key kv with
  | Some (Kv.L []) ->
      let ts = skip_section key ts in
      eval_template buf t kv ts section
  | Some (Kv.L ls) ->
      ListLabels.iter
        ~f:(fun kv' ->
          let kv = Kv.Map.union (fun _ _ r -> Some r) kv kv' in
          ignore (eval_template buf t kv ts key))
        ls;
      let ts = skip_section key ts in
      eval_template buf t kv ts section
  | Some _ -> raise (Apply_error (`Expected_list (key, ln)))
  | None -> raise (Apply_error (`Missing_key (key, ln)))

and eval_list_test_section ln buf t kv ts section key empty =
  match Kv.Map.get key kv with
  | Some (Kv.L []) when empty = `Empty ->
      let ts = eval_template buf t kv ts key in
      eval_template buf t kv ts section
  | Some (Kv.L (_ :: _)) when empty = `Not_empty ->
      let ts = eval_template buf t kv ts key in
      eval_template buf t kv ts section
  | Some (Kv.L _) ->
      let ts = skip_section key ts in
      eval_template buf t kv ts section
  | Some _ -> raise (Apply_error (`Expected_list (key, ln)))
  | None -> raise (Apply_error (`Missing_key (key, ln)))

and eval_exists_test_section ln buf t kv ts section key exists =
  match (Kv.Map.get key kv, exists) with
  | Some _, `Exists | None, `Not_exists ->
      let ts = eval_template buf t kv ts key in
      eval_template buf t kv ts section
  | _ ->
      let ts = skip_section key ts in
      eval_template buf t kv ts section

let apply t kv =
  let buf = Buffer.create 100 in
  try
    let ret = eval_template buf t kv t.template "" in
    assert (ret = []);
    Ok (Buffer.contents buf)
  with Apply_error err -> Error (err : err :> [> err ])
