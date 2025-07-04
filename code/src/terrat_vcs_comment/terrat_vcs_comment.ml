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
  val dirspace : el -> string
  val is_from_error_report : el -> bool
  val strategy : t -> el -> (Strategy.t, [> `Error ]) result Abb.Future.t
  val max_comment_length : int
end

module Make (M : S) = struct
  let break (e : M.el) =
    let limit = M.max_comment_length in
    let rec loop len curr acc =
      if len <= limit then acc @ [ curr ]
      else
        let part, remaining = CCString.take_drop limit curr in
        loop (len - limit) remaining (acc @ [ part ])
    in
    loop (M.rendered_length e) (M.content e) []

  let group (els : M.el list) =
    let e, s = CCList.partition M.is_from_error_report els in
    []

  let combine (els : M.el list) =
    let n = CCList.length els in
    let total = CCList.fold_left (fun acc e -> M.rendered_length e + acc) 0 els in
    match (total / M.max_comment_length) + 1 with
    | x when x <= n -> CCList.flat_map break els
    | _ -> []

  let run t els =
    let open Abb.Future.Infix_monad in
    raise (Failure "nyi")
end

(*
let combine settings strategy inputs =
  (* TODO: refactor this *)
  let compare (a : output) (b : output) =
    let id_cmp = String.compare a.id b.id in
    let error_cmp = Bool.compare a.is_error b.is_error in
    let dirspace_cmp = String.compare a.dirspace b.dirspace in
    let index_cmp = Int.compare a.index b.index in

    match (id_cmp, error_cmp, dirspace_cmp, index_cmp) with
    | id, _, _, _ when id <> 0 -> id
    | _, err, _, _ when err <> 0 -> err
    | _, _, dir, _ when dir <> 0 -> dir
    | _, _, _, idx when idx <> 0 -> idx
    | _ -> -1
  in
  let out =
    match strategy with
    | Append -> CCList.flat_map (break settings) inputs
    | Delete -> []
    | Minimize -> []
  in
  CCList.sort compare out

#require "containers";;
#require "uuidm";;
#mod_use "src/ouuid/ouuid.ml";;
#mod_use "src/comment/comment.ml";;
open Comment;;

let s = Settings.{ max_length = 10; max_requests = 3};;
let st = Strategy.Append;;
let c1 = CCString.init 15 (fun _ -> 'a') ^ CCString.init 15 (fun _ -> 'b') ^ CCString.init 17 (fun _ -> 'c');;
let i1 = ("a", c1, true);;
module P = Make(Output)(Settings)(Strategy);;
P.break s i1;;
let i2 = [("a", CCString.init 5 (fun _ -> 'a'), true); ("b", CCString.init 15 (fun _ -> 'b'), false); ("c", CCString.init 17 (fun _ -> 'c'), true)];;
P.combine s st i2;;
*)
