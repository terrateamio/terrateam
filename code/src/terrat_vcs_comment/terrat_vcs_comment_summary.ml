type tf_stats = {
  created : int;
  updated : int;
  deleted : int;
  replaced : int;
}
[@@deriving ord, show]

module type S = sig
  type t
  type el [@@deriving ord, show]
  type comment_id [@@deriving ord, show]

  val query_comment_id :
    t -> pull_number:int64 -> repo:int64 -> (comment_id option, [> `Error ]) result Abb.Future.t

  val query_summary_elements :
    t -> pull_number:int64 -> repo:int64 -> (el list, [> `Error ]) result Abb.Future.t

  val upsert_summary : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t
  val rendered_length : t -> el list -> int
  val max_comment_length : int
end

module Make (M : S) = struct
  let run t els =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Alr = Abbs_future_combinators.List_result in
    raise (Failure "nyi")
end
