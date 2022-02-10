module type S = sig
  type elt
  type t

  val compare : elt -> elt -> int
  val to_paginate : elt -> string list
  val has_another_page : t -> bool
  val items : t -> elt list
end

type dir =
  | Next
  | Prev

module Make (M : S) = struct
  type t = {
    page_param : string;
    dir : dir;
    uri : Uri.t;
    page : M.t;
  }

  let make ?(page_param = "page") page uri =
    match Uri.get_query_param' uri page_param with
    | None -> Some { page_param; dir = Next; uri; page }
    | Some ("n" :: pg) -> Some { page_param; dir = Next; uri; page }
    | Some ("p" :: pg) -> Some { page_param; dir = Prev; uri; page }
    | Some _ -> None

  let to_next t =
    let results_len = List.length (M.items t.page) in
    match t.dir with
    | Next when results_len > 0 && M.has_another_page t.page ->
        let last = M.items t.page |> CCList.rev |> CCList.hd in
        t.uri
        |> CCFun.flip Uri.remove_query_param "page"
        |> CCFun.flip Uri.add_query_param ("page", "n" :: M.to_paginate last)
        |> CCOpt.return
    | Prev when Uri.get_query_param t.uri t.page_param = None -> None
    | Prev ->
        let first = M.items t.page |> CCList.rev |> CCList.hd in
        t.uri
        |> CCFun.flip Uri.remove_query_param "page"
        |> CCFun.flip Uri.add_query_param ("page", "n" :: M.to_paginate first)
        |> CCOpt.return
    | Next -> None

  let to_prev t =
    let results_len = List.length (M.items t.page) in
    match t.dir with
    | Next when Uri.get_query_param t.uri t.page_param = None -> None
    | Next ->
        let last = CCList.hd (M.items t.page) in
        t.uri
        |> CCFun.flip Uri.remove_query_param "page"
        |> CCFun.flip Uri.add_query_param ("page", "p" :: M.to_paginate last)
        |> CCOpt.return
    | Prev when results_len > 0 && M.has_another_page t.page ->
        let first = M.items t.page |> CCList.hd in
        t.uri
        |> CCFun.flip Uri.remove_query_param "page"
        |> CCFun.flip Uri.add_query_param ("page", "p" :: M.to_paginate first)
        |> CCOpt.return
    | Prev -> None

  let items t = M.items t.page
end
