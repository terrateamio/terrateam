module Path = struct
  type 'a t = int -> string -> (int * 'a) option

  let extract idx s =
    if s.[idx] = '/' then
      match CCString.index_from_opt s (idx + 1) '/' with
        | Some eidx -> Some (eidx, CCString.sub s (idx + 1) (eidx - idx - 1))
        | None      -> Some (String.length s, CCString.sub s (idx + 1) (String.length s - idx - 1))
    else
      None

  let ud f idx s =
    let open CCOpt.Infix in
    extract idx s >>= fun (idx, s) -> CCOpt.wrap f s >>= fun v -> v >>= fun v -> Some (idx, v)

  let string = ud CCOpt.return

  let int = ud (CCFun.compose int_of_string CCOpt.return)
end

module Query = struct
  type 'a t = string * (string -> 'a option)

  let ud n f = (n, f)

  let string n = (n, CCOpt.return)

  let int n = (n, CCOpt.wrap int_of_string)
end

type ('f, 'r) t =
  (* | Host : string -> ('r, 'r) t *)
  | Rel : ('r, 'r) t
  | Path_const : (('f, 'r) t * string) -> ('f, 'r) t
  | Path_var   : (('f, 'a -> 'r) t * 'a Path.t) -> ('f, 'r) t
  | Query_var  : (('f, 'a -> 'r) t * 'a Query.t) -> ('f, 'r) t

module Route = struct
  (* Remember the name of Furi.t first *)
  type ('f, 'r) _t = ('f, 'r) t

  type 'r t = Route : (('f, 'r) _t * 'f) -> 'r t
end

let rel = Rel

let ( / ) t s = Path_const (t, s)

let ( /% ) t v = Path_var (t, v)

let ( /? ) t v = Query_var (t, v)

let route t f = Route.Route (t, f)

let ( --> ) = route

module Witness = struct
  type ('f, 'r) t =
    | Start : ('r, 'r) t
    | Var   : (('f, 'a -> 'r) t * 'a) -> ('f, 'r) t
end

let rec test_uri : type f r. Uri.t -> (f, r) t -> (int * (f, r) Witness.t) option =
 fun uri t ->
  let path = Uri.path uri in
  match t with
    | Rel                   -> Some (0, Witness.Start)
    | Path_const (t, s)     ->
        let open CCOpt.Infix in
        test_uri uri t
        >>= fun (idx, wit) ->
        if idx < String.length path then
          let s = "/" ^ s in
          let len = String.length s in
          if CCString.is_sub ~sub:s 0 path idx ~sub_len:len then
            Some (idx + len, wit)
          else
            None
        else
          None
    | Path_var (t, v)       ->
        let open CCOpt.Infix in
        test_uri uri t
        >>= fun (idx, wit) ->
        if idx < String.length path then
          v idx path >>= fun (idx, value) -> Some (idx, Witness.Var (wit, value))
        else
          None
    | Query_var (t, (n, v)) ->
        let open CCOpt.Infix in
        test_uri uri t
        >>= fun (idx, wit) ->
        Uri.get_query_param uri n
        >>= fun q -> v q >>= fun value -> Some (idx, Witness.Var (wit, value))

let rec apply_uri' : type f r x. (f, x) Witness.t -> (x -> r) -> f -> r =
 fun w k ->
  let open Witness in
  match w with
    | Start        -> k
    | Var (wit, v) ->
        let k f = k (f v) in
        apply_uri' wit k

let apply_uri : type f r. (f, r) Witness.t -> f -> r = fun wit -> apply_uri' wit (fun x -> x)

let rec match_uri ~default rs uri =
  match rs with
    | []                       -> default uri
    | Route.Route (t, f) :: rs -> (
        match test_uri uri t with
          | Some (idx, wit) when String.length (Uri.path uri) = idx ->
              (* Ensure the whole URI path has been consumed *)
              apply_uri wit f
          | Some _ | None -> match_uri ~default rs uri )
