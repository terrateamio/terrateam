module Capture = struct
  type t = { c_s : int
           ; c_e : int
           ; str : string
           }

  let start t = t.c_s
  let stop t = t.c_e

  let to_string t =
    String.sub t.str t.c_s (t.c_e - t.c_s)
end

module Match = struct
  type t = { range    : (int * int)
           ; captures : Capture.t list
           ; src      : string
           }

  let range t = t.range

  let to_string t =
    let (start, stop) = t.range in
    String.sub t.src start (stop - start)

  let captures t = t.captures
end

module S = struct
  type t = { start    : int
           ; src      : string
           ; src_len  : int
           ; pat      : string
           ; pat_len  : int
           ; captures : Capture.t list
           }

  let create ~start ~src ~pat =
    { start    = start
    ; src      = src
    ; src_len  = String.length src
    ; pat      = pat
    ; pat_len  = String.length pat
    ; captures = []
    }
end

module Pos : sig
  type 'a t
  type src
  type pat

  val src_of_int : int -> src t
  val pat_of_int : int -> pat t

  val inc    : ?n:int -> 'a t -> 'a t
  val to_int : 'a t -> int

  val is_src_e : S.t -> src t -> bool
  val is_pat_e : S.t -> pat t -> bool

  val src_c : S.t -> src t -> char
  val pat_c : S.t -> pat t -> char
end = struct
  type 'a t = int
  type src
  type pat

  let src_of_int i = i
  let pat_of_int i = i

  let inc ?(n = 1) t = t + n
  let to_int t = t

  let is_src_e s t = t >= s.S.src_len
  let is_pat_e s t = t >= s.S.pat_len

  let src_c s t = s.S.src.[t]
  let pat_c s t = s.S.pat.[t]
end

type t = string

let rec validate_pattern captures p s len =
  if p >= len && captures = 0 then
    Some s
  else if p >= len then
    None
  else begin
    match s.[p] with
      | '%' when p + 1 >= len ->
        None
      | '%' when s.[p + 1] = 'b' && p + 3 < len ->
        validate_pattern captures (p + 4) s len
      | '%' when s.[p + 1] = 'b' ->
        None
      | '%' ->
        validate_pattern captures (p + 2) s len
      | '[' ->
        validate_bracket captures (p + 1) s len
      | '(' ->
        validate_pattern (captures + 1) (p + 1) s len
      | ')' when captures = 0 ->
        None
      | ')' ->
        validate_pattern (captures - 1) (p + 1) s len
      | _ ->
        validate_pattern captures (p + 1) s len
  end
and validate_bracket captures p s len =
  if p >= len then
    None
  else begin
    match s.[p] with
      | '%' when p + 1 < len ->
        validate_bracket captures (p + 2) s len
      | ']' ->
        validate_pattern captures (p + 1) s len
      | _ ->
        validate_bracket captures (p + 1) s len
  end

let of_string s =
  validate_pattern 0 0 s (String.length s)

let is_special _ = false

let is_alpha = function
  | 'A'..'Z' | 'a'..'z' -> true
  | _                   -> false

(* Taken from the definition of the man page of iscntrl *)
let is_cntrl = function
  | '\000' | '\001' | '\002' | '\003' | '\004'
  | '\005' | '\006' | '\007' | '\010' | '\011'
  | '\012' | '\013' | '\014' | '\015' | '\016'
  | '\017' | '\020' | '\021' | '\022' | '\023'
  | '\024' | '\025' | '\026' | '\027' | '\030'
  | '\031' | '\032' | '\033' | '\034' | '\035'
  | '\036' | '\037' | '\177' ->
    true
  | _ ->
    false

let is_digit = function
  | '0'..'9' -> true
  | _        -> false

let is_lower = function
  | 'a'..'z' -> true
  | _        -> false

(* Taken from man page for ispunct *)
let is_punct = function
  | '!' | '"' | '#' | '$' | '%' | '\''
  | '&' | '(' | ')' | '*' | '+' | ','
  | '-' | '.' | '/' | ':' | ';' | '\\'
  | '<' | '=' | '>' | '?' | '@' | '['
  | ']' | '^' | '_' | '`' | '{' | '|'
  | '}' | '~' ->
    true
  | _ ->
    false

let is_space = function
  | ' ' | '\t' | '\n' | '\r' -> true
  | _                        -> false

let is_upper = function
  | 'A'..'Z' -> true
  | _        -> false

let is_alpha c =
  is_upper c || is_lower c

let is_alnum c =
  is_alpha c || is_digit c

let is_xdigit = function
  | '0'..'9' | 'a'..'f' | 'A'..'F' -> true
  | _                              -> false

let is_graph c =
  (is_alnum c || is_digit c || is_punct c) && c <> ' '

let rec bracket_classend s pat_p =
  match Pos.pat_c s pat_p with
    | ']' ->
      Pos.inc pat_p
    | '%' ->
      bracket_classend s (Pos.inc ~n:2 pat_p)
    | _ ->
      bracket_classend s (Pos.inc pat_p)

let classend s pat_p =
  if Pos.is_pat_e s pat_p then
    pat_p
  else begin
    match Pos.pat_c s pat_p with
      | '%' -> Pos.inc ~n:2 pat_p
      | '[' -> bracket_classend s (Pos.inc pat_p)
      | _   -> Pos.inc pat_p
  end

let mtch_char_class c p =
  let lp = Char.lowercase_ascii p in
  let f =
    match lp with
      | 'a' -> is_alpha
      | 'c' -> is_cntrl
      | 'd' -> is_digit
      | 'g' -> is_graph
      | 'l' -> is_lower
      | 'p' -> is_punct
      | 's' -> is_space
      | 'u' -> is_upper
      | 'w' -> is_alnum
      | 'x' -> is_xdigit
      | c   -> ((=) c)
  in
  (p = lp && f c) || (p <> lp && not (f c))

(*
 * This depends on digits and the alphabet being in lexigraphical order
 *)
let between_range c pat_prev pat_next =
  c >= pat_prev && c <= pat_next

let prev_pat_c s pat_p =
  Pos.pat_c s (Pos.inc ~n:(-1) pat_p)

let next_pat_c s pat_p =
  Pos.pat_c s (Pos.inc pat_p)

let rec mtch_bracket_pat c s pat_p =
  match Pos.pat_c s pat_p with
    | ']' ->
      false
    | '%' when Pos.pat_c s (Pos.inc pat_p) = c ->
      true
    | '%' ->
      mtch_bracket_pat c s (Pos.inc ~n:2 pat_p)
    | '-' when Pos.pat_c s (Pos.inc pat_p) = ']' ->
      '-' = c
    | '-' when between_range c (prev_pat_c s pat_p) (next_pat_c s pat_p) ->
      (*
       * In this way the first char of a range will be tested twice, once as
       * an individual char and once as part of the range, but this is
       * probably not expensive enough to matter
       *)
      true
    | '-' ->
      mtch_bracket_pat c s (Pos.inc ~n:2 pat_p)
    | p when c = p ->
      true
    | _ ->
      mtch_bracket_pat c s (Pos.inc pat_p)

let mtch_bracket_class c s pat_p =
  if Pos.pat_c s pat_p = '^' then
    not (mtch_bracket_pat c s (Pos.inc pat_p))
  else
    mtch_bracket_pat c s pat_p

let mtch_single src_p pat_p s =
  if not (Pos.is_src_e s src_p) then
    match Pos.pat_c s pat_p with
      | '%' -> mtch_char_class (Pos.src_c s src_p) (Pos.pat_c s (Pos.inc pat_p))
      | '[' -> mtch_bracket_class (Pos.src_c s src_p) s (Pos.inc pat_p)
      | '.' -> true
      | c   -> c = Pos.src_c s src_p
  else
    false

let rec furthest_mtch_single src_p pat_p s =
  if mtch_single src_p pat_p s then
    furthest_mtch_single (Pos.inc src_p) pat_p s
  else
    src_p

let src_and_pat_consumed s src_p pat_p =
  Pos.is_pat_e s pat_p && Pos.is_src_e s src_p

let create_match s src_p =
  Match.({ range    = (s.S.start, Pos.to_int src_p)
         ; src      = s.S.src
         ; captures = List.rev s.S.captures
         })

let is_balance_mtch s pat_p =
  Pos.pat_c s pat_p = '%' && Pos.pat_c s (Pos.inc pat_p) = 'b'

let src_eq_pat s src_p pat_p =
  not (Pos.is_src_e s src_p) &&
    not (Pos.is_pat_e s pat_p) &&
    Pos.src_c s src_p = Pos.pat_c s pat_p

let rec do_mtch src_p pat_p = function
  | s when Pos.is_pat_e s pat_p ->
    Some (create_match s src_p)
  | s when Pos.pat_c s pat_p = '(' -> begin
    let pat_p = Pos.inc pat_p in
    let capture = Capture.({ c_s = Pos.to_int src_p
                           ; c_e = Pos.to_int src_p
                           ; str = s.S.src
                           })
    in
    let s = { s with S.captures = capture::s.S.captures } in
    if Pos.pat_c s pat_p = ')' then
      do_mtch src_p (Pos.inc pat_p) s
    else
      do_mtch src_p pat_p s
  end
  | { S.captures = c::cs; _ } as s when Pos.pat_c s pat_p = ')' -> begin
    let capture = { c with Capture.c_e = Pos.to_int src_p } in
    do_mtch src_p (Pos.inc pat_p) { s with S.captures = capture::cs }
  end
  | s when is_balance_mtch s pat_p && src_eq_pat s src_p (Pos.inc ~n:2 pat_p) ->
    mtch_balance 0 src_p (Pos.inc ~n:2 pat_p) s
  | s when is_balance_mtch s pat_p ->
    None
  | s when Pos.pat_c s pat_p = '$' && src_and_pat_consumed s src_p (Pos.inc pat_p) ->
    Some (create_match s src_p)
  | s -> begin
    let class_e = classend s pat_p in
    if not (Pos.is_pat_e s class_e) then
      match (mtch_single src_p pat_p s, Pos.pat_c s class_e) with
        | (false, '*')
        | (false, '-')
        | (false, '?') ->
          do_mtch src_p (Pos.inc class_e) s
        | (false, _) ->
          None

        | (true, '+') ->
          max_expand (Pos.inc src_p) pat_p s (Pos.inc class_e)
        | (true, '*') ->
          max_expand src_p pat_p s (Pos.inc class_e)
        | (true, '-') ->
          min_expand src_p pat_p s (Pos.inc class_e)
        | (true, '?') ->
          do_mtch (Pos.inc src_p) (Pos.inc class_e) s
        | (true, _) ->
          do_mtch (Pos.inc src_p) class_e s
    else if mtch_single src_p pat_p s then
      Some (create_match s (Pos.inc src_p))
    else
      None
  end
and max_expand src_p pat_p s class_e =
  let src_p_e = furthest_mtch_single src_p pat_p s in
  reduce_furthest_mtch_single src_p class_e s src_p_e
and reduce_furthest_mtch_single src_p pat_p s src_p_e =
  if src_p = src_p_e then
    do_mtch src_p pat_p s
  else begin
    match do_mtch src_p_e pat_p s with
      | Some ms ->
        Some ms
      | None ->
        reduce_furthest_mtch_single src_p pat_p s (Pos.inc ~n:(-1) src_p_e)
  end
and min_expand src_p pat_p s class_e =
  match do_mtch src_p class_e s with
    | Some ms ->
      Some ms
    | None when mtch_single src_p pat_p s ->
      min_expand (Pos.inc src_p) pat_p s class_e
    | None ->
      None
and mtch_balance depth src_p pat_p = function
  | s when Pos.is_src_e s src_p ->
    None
  | s when Pos.src_c s src_p = Pos.pat_c s pat_p ->
    mtch_balance (depth + 1) (Pos.inc src_p) pat_p s
  | s when Pos.src_c s src_p = Pos.pat_c s (Pos.inc pat_p) && depth = 1 ->
    do_mtch (Pos.inc src_p) (Pos.inc ~n:2 pat_p) s
  | s when Pos.src_c s src_p = Pos.pat_c s (Pos.inc pat_p) ->
    mtch_balance (depth - 1) (Pos.inc src_p) pat_p s
  | s ->
    mtch_balance depth (Pos.inc src_p) pat_p s

let rec mtch ?(start = 0) str t =
  let src_p = Pos.src_of_int start in
  let pat_p = Pos.pat_of_int 0 in
  match S.create ~start ~src:str ~pat:t with
    | s when Pos.is_src_e s src_p || Pos.is_pat_e s pat_p ->
      None
    | s when Pos.pat_c s pat_p = '^' ->
      do_mtch src_p (Pos.inc pat_p) s
    | s -> begin
      match do_mtch src_p pat_p s with
        | Some m -> Some m
        | None   -> mtch ~start:(start + 1) str t
    end

let find ?(start = 0) str t =
  match mtch ~start str t with
    | Some m -> Some (Match.range m)
    | None   -> None

let substitute ?(start = 0) ~s ~r t =
  match mtch ~start s t with
    | Some m ->
      let rep = r m in
      let rep_len = String.length rep in
      let s_len = String.length s in
      let (start, stop) = Match.range m in
      let len = s_len - (stop - start) + rep_len in
      let ret = Bytes.create len in
      Bytes.blit_string s 0 ret 0 start;
      Bytes.blit_string rep 0 ret start rep_len;
      Bytes.blit_string s stop ret (start + rep_len) (s_len - stop);
      Some (Bytes.to_string ret)
    | None ->
      None

let capture_len = 2

let split_on_capture_variables s =
  let rec split acc idx s =
    match String.index_from s idx '%' with
      | n when n + 1 < String.length s && is_digit s.[n + 1] ->
        let sub = String.sub s idx (n - idx) in
        let capture = String.sub s n capture_len in
        split (capture::sub::acc) (n + 2) s
      | n when n + 1 >= String.length s ->
        let sub = String.sub s idx (String.length s - idx) in
        List.rev (sub::acc)
      | n ->
        split acc (n + 1) s
      | exception Not_found ->
        let sub = String.sub s idx (String.length s - idx) in
        List.rev (sub::acc)
  in
  split [] 0 s

let replace_with_match splits m =
  let captures = Match.captures m in
  String.concat
    ""
    (List.map
       (fun s ->
         if String.length s = capture_len && s.[0] = '%' && is_digit s.[1] then
           let n = Char.code s.[1] - Char.code '0' in
           Capture.to_string (List.nth captures (n - 1))
         else
           s)
       splits)

let rep_str s =
  let splits = split_on_capture_variables s in
  replace_with_match splits
