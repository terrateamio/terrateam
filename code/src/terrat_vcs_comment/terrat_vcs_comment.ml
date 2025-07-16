module Strategy = struct
  type t =
    | Append
    | Delete
    | Minimize
  [@@deriving ord, show]
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
  val rendered_length : el list -> int
  val dirspace : el -> Terrat_dirspace.t
  val is_success : el -> bool
  val strategy : el -> Strategy.t
  val compact : el -> el
  val compare_el : el -> el -> int
  val max_comment_length : int
end

module Make (M : S) = struct
  module By_strategy = Terrat_data.Group_by (struct
    type t = M.el
    type key = Strategy.t

    let key = M.strategy
    let compare = Strategy.compare
  end)

  let partition_by_strategy els = By_strategy.group els
  let compact e = if M.rendered_length [ e ] < M.max_comment_length then e else M.compact e

  let split_by_size els =
    let combine (groups, curr_acc) r =
      if M.rendered_length (r :: curr_acc) < M.max_comment_length then (groups, r :: curr_acc)
      else (CCList.rev curr_acc :: groups, [ r ])
    in
    let groups, rest = CCList.fold_left combine ([], []) els in
    let x =
      CCList.rev (CCList.rev rest :: groups) |> CCList.filter CCFun.(CCList.is_empty %> not)
    in
    x

  let append_single t (els : M.el list) =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Alr = Abbs_future_combinators.List_result in
    M.post_comment t els >>= fun cid -> M.upsert_comment_id t els cid

  let append t (elss : M.el list list) =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Alr = Abbs_future_combinators.List_result in
    Abbs_future_combinators.List_result.iter ~f:(append_single t) elss

  let run t els =
    let open Abb.Future.Infix_monad in
    let module Alr = Abbs_future_combinators.List_result in
    let compressed = CCList.map compact els in
    let sorted = CCList.sort M.compare_el compressed in
    let groups = partition_by_strategy sorted in
    let split = CCList.map (fun (k, v) -> (k, split_by_size v)) groups in
    Abbs_future_combinators.List_result.iter
      ~f:(function
        | Strategy.Append, els -> append t els
        | _, els -> raise (Failure "nyi"))
      split
end
