module S = struct
  type t = { client : Terrat_vcs_api_github.Client.t; }

  type el = {
    (* TODO: Check if we really need this *)
    content : string;
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type comment_id = int

  let query_comment_id t el = 1000
  let query_els_for_comment_id t cid = []
  let upsert_comment_id t els cid = Abb.Future.return (Ok ())
  let delete_comment t comment_id = Abb.Future.return (Ok ())
  let minimize_comment t comment_id = Abb.Future.return (Ok ())
  let post_comment t els = 
    let module Gh = Terrat_vcs_api_github in
    let _request_id = "test" in
    Abb.Future.return (Ok 1)
  let rendered_length els = CCList.fold_left (fun acc el -> acc + CCString.length el.content) 0 els
  let dirspace el = el.dirspace
  let is_success el = el.is_success
  let strategy el = el.strategy

  (* TODO: For testing purposes only, will change this later *)
  (* TODO: Setup proper templates later *)
  let compact el = { el with content = "Template redirecting to the UI!" }

  (* Github Limits it to 2^16 = 65536
     https://github.com/mshick/add-pr-comment/issues/93#issuecomment-1531415467
     I set it to a smaller value *)
  let max_comment_length = 32768
end
