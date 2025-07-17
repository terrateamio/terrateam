module Api = Terrat_vcs_api_github

module S = struct
  type t = { client : Api.Client.t }

  type el = {
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    has_changed : bool;
    rendered_length : int;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type comment_id = int

  module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t el = 1000
  let query_els_for_comment_id t cid = []
  let upsert_comment_id t els cid = Abb.Future.return (Ok ())
  let delete_comment t comment_id = Abb.Future.return (Ok ())
  let minimize_comment t comment_id = Abb.Future.return (Ok ())

  let post_comment t els =
    let module Gh = Terrat_vcs_api_github in
    let _request_id = "test" in
    Abb.Future.return (Ok 1)

  let rendered_length els = CCList.fold_left (fun acc el -> acc + el.rendered_length) 0 els
  let strategy el = el.strategy

  (* TODO: For testing purposes only, will change this later *)
  (* TODO: Wirte with proper templates on Tmpl later *)
  let compact el = { el with rendered_length = 2048 }

  let compare_el el1 el2 =
    Cmp.compare
      (not el1.has_changed, el1.is_success, el1.dirspace)
      (not el2.has_changed, el2.is_success, el2.dirspace)

  (* Github Limits it to 2^16 = 65536
     https://github.com/mshick/add-pr-comment/issues/93#issuecomment-1531415467
     I set it to a smaller value *)
  let max_comment_length = 65536 / 2
end
