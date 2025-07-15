module S = struct
  type t = { config : Terrat_vcs_service_github_provider.Api.Config.t }

  type el = {
    (* TODO: Check if we really need this *)
    content : string;
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type comment_id = int

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
