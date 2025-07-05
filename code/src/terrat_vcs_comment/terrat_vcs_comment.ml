module Strategy = struct
  type t =
    | Append
    | Delete
    | Minimize
end

module type S = sig
  type t
  type el
  type comment_id

  val query_comment_id : t -> el -> (comment_id option, [> `Error ]) result Abb.Future.t
  val query_els_for_comment_id : t -> comment_id -> (el list, [> `Error ]) result Abb.Future.t
  val upsert_comment_id : t -> el list -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val delete_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t
  val rendered_length : el -> int
  val content : el -> string
  val dirspace : el -> Terrat_dirspace.t
  val is_from_error_report : el -> bool
  val strategy : t -> el -> (Strategy.t, [> `Error ]) result Abb.Future.t
  val max_comment_length : int
end

module Make (M : S) = struct
  (* Like, el, but with extra metadata *)
  type el_meta = {
    element : M.el;
    length : int;
  }

  module Pack = CCMap.Make (Int)

  type comment = {
    content : string;
    group_id : int;
    index : int;
  }

  let break e =
    let limit = M.max_comment_length in
    let rec loop len curr acc =
      if len <= limit then acc @ [ curr ]
      else
        let part, remaining = CCString.take_drop limit curr in
        loop (len - limit) remaining (acc @ [ part ])
    in
    loop (M.rendered_length e) (M.content e) []

  let partition predicate els =
    CCList.map (fun el -> { element = el; length = M.rendered_length el }) els
    |> CCList.sort (fun g1 g2 -> compare g1.length g2.length)
    |> CCList.partition predicate

  let group ems =
    let map : string list Pack.t = Pack.empty in
    let update map new_item = function
      | None -> Some new_item
      | Some curr -> Some (curr @ new_item)
    in
    let rec loop curr group_id prev_sum acc =
      match curr with
      | [] -> acc
      (* Happy path, all items we've consumed so far are smaller
         than the VCS limit *)
      | g :: gs when prev_sum + g.length + 1 <= M.max_comment_length ->
          let content = break g.element in
          let map = Pack.update group_id (update group_id content) map in
          loop gs group_id (prev_sum + g.length + 1) map
      (* If we ever hit somethig that is single-handedly bigger
         than the VCS limit. Cut the previous accumulated state,
         set a group just for the big element and move on. *)
      | g :: gs when g.length + 1 > M.max_comment_length ->
          let content = break g.element in
          let map = Pack.update (group_id + 1) (update group_id content) map in
          loop gs (group_id + 2) 0 map
      (* Wrap everything into a new group and move on to the 
         next one *)
      | g :: gs ->
          let content = break g.element in
          let map = Pack.update (group_id + 1) (update group_id content) map in
          loop gs (group_id + 1) 0 map
    in
    loop ems 0 0 map

  (* let combine (ems : el_meta list list) = CCList.mapi (fun i es -> to_comment (i + 1) es) ems *)

  let aggregate (els : M.el list) =
    let n = CCList.length els in
    let total = CCList.fold_left (fun acc e -> M.rendered_length e + acc) 0 els in
    let errors = CCList.sort sort_by_length e in
    let successes = CCList.sort sort_by_length s in
    match (total / M.max_comment_length) + 1 with
    | x when x <= n ->
        (* So everything can be aggregated into a single comment *)
        CCList.flat_map break els
    | _ -> []

  let run t els =
    let open Abb.Future.Infix_monad in
    raise (Failure "nyi")
end
