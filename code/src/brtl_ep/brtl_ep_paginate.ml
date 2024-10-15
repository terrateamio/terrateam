module type S = sig
  type cursor
  type query
  type t
  type err

  val next : ?cursor:cursor -> query -> (t, err) result Abb.Future.t
  val prev : ?cursor:cursor -> query -> (t, err) result Abb.Future.t
  val to_yojson : t -> Yojson.Safe.t
  val cursor_of_first : t -> string list option
  val cursor_of_last : t -> string list option
  val has_another_page : t -> bool
  val rspnc_of_err : token:string -> err -> Brtl_rspnc.t
end

module Dir = struct
  type t =
    | Next
    | Prev
end

module Param = struct
  module Typ = struct
    type 'a t = string list -> 'a option

    let ud f sl = f sl

    let ud' f = function
      | x :: _ -> f x
      | [] -> None

    let string = ud' CCOption.return

    let tuple (f1, f2) =
      ud (function
          | [ x1; x2 ] ->
              let open CCOption.Infix in
              (fun a b -> (a, b)) <$> f1 [ x1 ] <*> f2 [ x2 ]
          | _ -> None)

    let tuple3 (f1, f2, f3) =
      ud (function
          | [ x1; x2; x3 ] ->
              let open CCOption.Infix in
              (fun a b c -> (a, b, c)) <$> f1 [ x1 ] <*> f2 [ x2 ] <*> f3 [ x3 ]
          | _ -> None)

    let tuple4 (f1, f2, f3, f4) =
      ud (function
          | [ x1; x2; x3; x4 ] ->
              let open CCOption.Infix in
              (fun a b c d -> (a, b, c, d)) <$> f1 [ x1 ] <*> f2 [ x2 ] <*> f3 [ x3 ] <*> f4 [ x4 ]
          | _ -> None)
  end

  type 'a t = Dir.t * 'a

  let of_param typ =
    let open CCOption.Infix in
    function
    | "n" :: cursor -> (fun cursor -> (Dir.Next, cursor)) <$> typ cursor
    | "p" :: cursor -> (fun cursor -> (Dir.Prev, cursor)) <$> typ cursor
    | _ -> None
end

let string_of_dir = function
  | Dir.Next -> "n"
  | Dir.Prev -> "p"

let update_page_param page_param cursor dir uri =
  uri
  |> CCFun.flip Uri.remove_query_param page_param
  |> fun uri ->
  CCOption.map
    (fun cursor -> Uri.add_query_param uri (page_param, string_of_dir dir :: cursor))
    cursor

let encode_link rel uri = Printf.sprintf "<%s>; rel=\"%s\"" (Uri.to_string uri) rel
let merge_uri_base uri_base uri = Uri.with_path uri_base (Uri.path uri_base ^ Uri.path uri)

module Make (M : S) = struct
  type t = {
    dir : Dir.t;
    cursor : M.cursor option;
  }

  let run ?page ~page_param query ctx =
    let t =
      match page with
      | None -> { dir = Dir.Next; cursor = None }
      | Some (dir, cursor) -> { dir; cursor = Some cursor }
    in
    let f =
      match t.dir with
      | Dir.Next -> M.next
      | Dir.Prev -> M.prev
    in
    let open Abb.Future.Infix_monad in
    f ?cursor:t.cursor query
    >>= function
    | Ok results ->
        let body = results |> M.to_yojson |> Yojson.Safe.to_string in
        let next_cursor =
          match t.dir with
          | Dir.Next when M.has_another_page results -> M.cursor_of_last results
          | Dir.Next -> None
          | Dir.Prev -> M.cursor_of_last results
        in
        let prev_cursor =
          match t.dir with
          | Dir.Next when CCOption.is_none t.cursor -> None
          | Dir.Next -> M.cursor_of_first results
          | Dir.Prev when M.has_another_page results -> M.cursor_of_first results
          | Dir.Prev -> None
        in
        let merged_uri_base = merge_uri_base (Brtl_ctx.uri_base ctx) (Brtl_ctx.uri ctx) in
        let next_uri = update_page_param page_param next_cursor Dir.Next merged_uri_base in
        let prev_uri = update_page_param page_param prev_cursor Dir.Prev merged_uri_base in
        let link =
          CCString.concat
            ", "
            (CCOption.to_list (CCOption.map (encode_link "next") next_uri)
            @ CCOption.to_list (CCOption.map (encode_link "prev") prev_uri))
        in
        let headers =
          Cohttp.Header.of_list [ ("link", link); ("content-type", "application/json") ]
        in
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`OK body) ctx)
    | Error err ->
        Abb.Future.return
          (Brtl_ctx.set_response (M.rspnc_of_err ~token:(Brtl_ctx.token ctx) err) ctx)
end
