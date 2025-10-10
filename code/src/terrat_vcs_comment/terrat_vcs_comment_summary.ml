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

  val upsert_summary :
    t -> comment_id -> pull_number:int64 -> repo:int64 -> (unit, [> `Error ]) result Abb.Future.t

  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t
  val pull_request : t -> int64
  val rendered_length : t -> el list -> int
  val repo : t -> int64
  val repo_config : t -> Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t
  val max_comment_length : int
end

module Make (M : S) = struct
  let create_els t ~pull_number ~repo =
    let module Brc1 = Terrat_base_repo_config_v1 in
    let module N = Terrat_base_repo_config_v1.Notifications in
    let module Ns = N.Summary in
    let repo_config = M.repo_config t in
    let notification = Brc1.notifications repo_config in
    match notification.N.summary with
    | { Ns.enabled = true } -> M.query_summary_elements t ~pull_number ~repo
    | _ -> Abb.Future.return (Ok [])

  let run t =
    let open Abbs_future_combinators.Infix_result_monad in
    let pull_number = M.pull_request t in
    let repo = M.repo t in
    M.query_comment_id t ~pull_number ~repo
    >>= (function
    | Some comment_id -> M.minimize_comment t comment_id
    | None -> Abb.Future.return (Ok ()))
    >>= fun () ->
    create_els t ~pull_number ~repo
    >>= function
    | [] -> Abb.Future.return (Ok ())
    | els ->
        M.post_comment t els >>= fun comment_id -> M.upsert_summary t comment_id ~pull_number ~repo
end
