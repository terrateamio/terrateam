module Path = struct
  type 'a t = int -> string -> (int * 'a) option

  let extract idx s =
    if s.[idx] = '/' then
      match CCString.index_from_opt s (idx + 1) '/' with
      | Some eidx -> Some (eidx, Uri.pct_decode (CCString.sub s (idx + 1) (eidx - idx - 1)))
      | None ->
          Some
            (String.length s, Uri.pct_decode (CCString.sub s (idx + 1) (String.length s - idx - 1)))
    else None

  let ud f idx s =
    let open CCOption.Infix in
    extract idx s >>= fun (idx, s) -> CCOption.wrap f s >>= fun v -> v >>= fun v -> Some (idx, v)

  let string =
    ud (function
        | s when CCString.length s > 0 -> Some s
        | _ -> None)

  let int = ud (CCFun.compose int_of_string CCOption.return)

  let any idx s =
    if s.[idx] = '/' then
      let len = String.length s - idx - 1 in
      Some (String.length s, Uri.pct_decode (CCString.sub s (idx + 1) len))
    else None
end

module Query = struct
  type 'a t = string * (string list option -> 'a option)

  let ud n f =
    ( n,
      function
      | Some (v :: _) -> CCOption.(flatten (wrap f v))
      | Some [] | None -> None )

  let ud_array n f =
    ( n,
      function
      | Some vs -> CCOption.(flatten (wrap f vs))
      | None -> None )

  let option (n, f) =
    ( n,
      function
      | Some _ as v -> (
          match f v with
          | None -> None
          | r -> Some r)
      | None -> Some None )

  let option_default def (n, f) =
    ( n,
      function
      | Some _ as v -> f v
      | None -> Some def )

  let string n = ud n CCOption.return
  let int n = ud n CCFun.(int_of_string %> CCOption.return)

  let rec apply_arr' acc f = function
    | [] -> Some (List.rev acc)
    | v :: vs -> (
        match f (Some [ v ]) with
        | Some r -> apply_arr' (r :: acc) f vs
        | None -> None)

  let array (n, f) =
    ( n,
      function
      | Some vs -> apply_arr' [] f vs
      | None -> None )

  let present n =
    ( n,
      function
      | Some [] -> Some ()
      | Some _ | None -> None )
end

module Fragment = struct
  type 'a t = string option -> 'a option

  let ud f = function
    | Some v -> CCOption.(flatten (wrap f v))
    | None -> None

  let string = ud CCOption.return

  let option t = function
    | Some v -> (
        match CCOption.(flatten (wrap t (Some v))) with
        | None -> None
        | r -> Some r)
    | None -> Some None
end

type ('f, 'r) t =
  (* | Host : string -> ('r, 'r) t *)
  | Rel : string -> ('r, 'r) t
  | Path_const : (('f, 'r) t * string) -> ('f, 'r) t
  | Path_var : (('f, 'a -> 'r) t * 'a Path.t) -> ('f, 'r) t
  | Query_var : (('f, 'a -> 'r) t * 'a Query.t) -> ('f, 'r) t
  | Fragment_var : (('f, 'a -> 'r) t * 'a Fragment.t) -> ('f, 'r) t

module Route = struct
  (* Remember the name of Furi.t first *)
  type ('f, 'r) _t = ('f, 'r) t
  type 'r t = Route : (('f, 'r) _t * 'f) -> 'r t
end

let rel = Rel ""
let root s = Rel (CCString.rdrop_while (( = ) '/') s)
let ( / ) t s = Path_const (t, Uri.pct_encode ~component:`Path s)
let ( /% ) t v = Path_var (t, v)
let ( /? ) t v = Query_var (t, v)
let ( /$ ) t v = Fragment_var (t, v)
let route t f = Route.Route (t, f)
let ( --> ) = route

module Witness = struct
  (* Used to extract the original value from the witness *)
  type v_type =
    | Path
    | Query of (string * string list option)
    | Fragment of string option

  type ('f, 'r) t =
    | Start : ('r, 'r) t
    | Var : (('f, 'a -> 'r) t * 'a * v_type) -> ('f, 'r) t
end

let rec test_uri : type f r. Uri.t -> (f, r) t -> (int * (f, r) Witness.t) option =
 fun uri t ->
  let path = Uri.path uri in
  match t with
  | Rel s when CCString.is_sub ~sub:s 0 path 0 ~sub_len:(CCString.length s) ->
      Some (CCString.length s, Witness.Start)
  | Rel _ -> None
  | Path_const (t, s) ->
      let open CCOption.Infix in
      test_uri uri t
      >>= fun (idx, wit) ->
      if idx < String.length path then
        let s = "/" ^ s in
        let len = String.length s in
        if CCString.is_sub ~sub:s 0 path idx ~sub_len:len then Some (idx + len, wit) else None
      else None
  | Path_var (t, v) ->
      let open CCOption.Infix in
      test_uri uri t
      >>= fun (idx, wit) ->
      if idx < String.length path then
        v idx path >>= fun (idx, value) -> Some (idx, Witness.Var (wit, value, Witness.Path))
      else None
  | Query_var (t, (n, v)) ->
      let open CCOption.Infix in
      test_uri uri t
      >>= fun (idx, wit) ->
      let q = Uri.get_query_param' uri n in
      v q >>= fun value -> Some (idx, Witness.Var (wit, value, Witness.Query (n, q)))
  | Fragment_var (t, v) ->
      let open CCOption.Infix in
      test_uri uri t
      >>= fun (idx, wit) ->
      let fragment = Uri.fragment uri in
      v fragment >>= fun value -> Some (idx, Witness.Var (wit, value, Witness.Fragment fragment))

let rec apply_uri' : type f r x. (f, x) Witness.t -> (x -> r) -> f -> r =
 fun w k ->
  let open Witness in
  match w with
  | Start -> k
  | Var (wit, v, _) ->
      let k f = k (f v) in
      apply_uri' wit k

let apply : type f r. (f, r) Witness.t -> f -> r = fun wit -> apply_uri' wit (fun x -> x)

module Match = struct
  type 'r t = Match : (int * Uri.t * 'f * ('f, 'r) Witness.t) -> 'r t

  let apply (Match (_, _, f, wit)) = apply wit f

  let consumed_path (Match (idx, uri, _, _)) =
    let path = Uri.path uri in
    String.sub path 0 idx

  let remaining_path (Match (idx, uri, _, _)) =
    let path = Uri.path uri in
    String.sub path idx (String.length path - idx)

  let rec equal' : type f1 r1 f2 r2. (f1, r1) Witness.t -> (f2, r2) Witness.t -> bool =
   fun wit1 wit2 ->
    let open Witness in
    match (wit1, wit2) with
    | Start, Start -> true
    | Var (wit1', _, v1), Var (wit2', _, v2) when v1 = v2 -> equal' wit1' wit2'
    | _ -> false

  let equal (Match (_, _, _, wit1) as t1) (Match (_, _, _, wit2) as t2) =
    consumed_path t1 = consumed_path t2 && equal' wit1 wit2
end

let match_uri ?(must_consume_path = true) (Route.Route (t, f)) uri =
  match test_uri uri t with
  | Some (idx, wit) when (not must_consume_path) || String.length (Uri.path uri) = idx ->
      Some (Match.Match (idx, uri, f, wit))
  | Some _ | None -> None

let rec first_match ?(must_consume_path = true) rs uri =
  match rs with
  | [] -> None
  | r :: rs -> (
      match match_uri ~must_consume_path r uri with
      | Some _ as r -> r
      | None -> first_match ~must_consume_path rs uri)

let route_uri ?(must_consume_path = true) ~default rs uri =
  match first_match ~must_consume_path rs uri with
  | Some m -> Match.apply m
  | None -> default uri
