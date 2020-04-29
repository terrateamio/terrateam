module Ctx = Brtl_ctx
module Rspnc = Brtl_rspnc

module Handler = struct
  type t = (string, unit) Ctx.t -> (string, Rspnc.t) Ctx.t Abb.Future.t
end

module Route = struct
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
    | Post_var   : (('f, 'a -> 'r) t * 'a Query.t) -> ('f, 'r) t

  module Route = struct
    (* Remember the name of Furi.t first *)
    type ('f, 'r) _t = ('f, 'r) t

    type 'r t = Route : (('f, 'r) _t * 'f) -> 'r t
  end

  let rel = Rel

  let ( / ) t s = Path_const (t, s)

  let ( /% ) t v = Path_var (t, v)

  let ( /? ) t v = Query_var (t, v)

  let ( /* ) t v = Post_var (t, v)

  let route t f = Route.Route (t, f)

  let ( --> ) = route

  module Witness = struct
    type ('f, 'r) t =
      | Start : ('r, 'r) t
      | Var   : (('f, 'a -> 'r) t * 'a) -> ('f, 'r) t
  end

  let rec test_ctx :
      type f r. ('a, 'b) Brtl_ctx.t -> Uri.t -> (f, r) t -> (int * (f, r) Witness.t) option =
   fun ctx body t ->
    let uri = Brtl_ctx.Request.uri (Brtl_ctx.request ctx) in
    let path = Uri.path uri in
    match t with
      | Rel                   -> Some (0, Witness.Start)
      | Path_const (t, s)     ->
          let open CCOpt.Infix in
          test_ctx ctx body t
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
          test_ctx ctx body t
          >>= fun (idx, wit) ->
          if idx < String.length path then
            v idx path >>= fun (idx, value) -> Some (idx, Witness.Var (wit, value))
          else
            None
      | Query_var (t, (n, v)) ->
          let open CCOpt.Infix in
          test_ctx ctx body t
          >>= fun (idx, wit) ->
          Uri.get_query_param uri n
          >>= fun q -> v q >>= fun value -> Some (idx, Witness.Var (wit, value))
      | Post_var (t, (n, v))  ->
          let open CCOpt.Infix in
          test_ctx ctx body t
          >>= fun (idx, wit) ->
          Uri.get_query_param body n
          >>= fun q -> v q >>= fun value -> Some (idx, Witness.Var (wit, value))

  let rec apply_ctx' : type f r x. (f, x) Witness.t -> (x -> r) -> f -> r =
   fun w k ->
    let open Witness in
    match w with
      | Start        -> k
      | Var (wit, v) ->
          let k f = k (f v) in
          apply_ctx' wit k

  let apply_ctx : type f r. (f, r) Witness.t -> f -> r = fun wit -> apply_ctx' wit (fun x -> x)

  let rec match_ctx' ~default rs ctx body =
    match rs with
      | []                       -> default ctx
      | Route.Route (t, f) :: rs -> (
          let uri = Brtl_ctx.Request.uri (Brtl_ctx.request ctx) in
          match test_ctx ctx body t with
            | Some (idx, wit) when String.length (Uri.path uri) = idx ->
                (* Ensure the whole URI path has been consumed *)
                apply_ctx wit f
            | Some _ | None -> match_ctx' ~default rs ctx body )

  let match_ctx ~default rs ctx =
    let body = Uri.of_string ("?" ^ Brtl_ctx.body ctx) in
    match_ctx' ~default rs ctx body
end

module Method = struct
  type t = Cohttp.Code.meth
end

type t = {
  default : Handler.t;
  routes : (Method.t, (string, unit) Brtl_ctx.t -> Handler.t) Hashtbl.t;
}

let create ~default routes_list =
  let route_default _ = default in
  let tmp = Hashtbl.create 10 in
  ListLabels.iter ~f:(fun (meth, route) -> CCHashtbl.add_list tmp meth route) routes_list;
  let routes = Hashtbl.create 10 in
  Hashtbl.iter
    (fun meth rts -> Hashtbl.add routes meth (Route.match_ctx ~default:route_default rts))
    tmp;
  { default; routes }

let route ctx t =
  match CCHashtbl.get t.routes Ctx.(Request.meth (request ctx)) with
    | Some routes -> routes ctx
    | None        -> t.default
