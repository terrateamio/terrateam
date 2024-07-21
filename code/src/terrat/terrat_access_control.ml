type query_err = [ `Error ] [@@deriving show]
type err = query_err [@@deriving show]

let terrateam_repo_config = [ ".terrateam/config.yml"; ".terrateam/config.yaml" ]

module Policy = struct
  type t = {
    tag_query : Terrat_tag_query.t;
    policy : Terrat_base_repo_config_v1.Access_control.Match_list.t;
  }
  [@@deriving show]
end

module R = struct
  module Deny = struct
    type t = {
      change_match : Terrat_change_match2.Dirspace_config.t;
      policy : Terrat_base_repo_config_v1.Access_control.Match_list.t option;
    }
    [@@deriving show]
  end

  type t = {
    pass : Terrat_change_match2.Dirspace_config.t list;
    deny : Deny.t list;
  }
  [@@deriving show]
end

module type S = sig
  type ctx

  val query :
    ctx ->
    Terrat_base_repo_config_v1.Access_control.Match.t ->
    (bool, [> query_err ]) result Abb.Future.t

  val set_user : string -> ctx -> ctx
end

module Make (S : S) = struct
  let is_repo_config_change =
    CCList.exists
      Terrat_change.Diff.(
        function
        | Add { filename } | Change { filename } | Remove { filename } ->
            CCList.mem ~eq:CCString.equal filename terrateam_repo_config
        | Move { filename; previous_filename } ->
            CCList.mem ~eq:CCString.equal filename terrateam_repo_config
            || CCList.mem ~eq:CCString.equal previous_filename terrateam_repo_config)

  let rec test_queries ctx = function
    | [] -> Abb.Future.return (Ok None)
    | q :: qs -> (
        let open Abbs_future_combinators.Infix_result_monad in
        S.query ctx q
        >>= function
        | true -> Abb.Future.return (Ok (Some q))
        | false -> test_queries ctx qs)

  let eval_repo_config ctx terrateam_config_change diff =
    let open Abbs_future_combinators.Infix_result_monad in
    if is_repo_config_change diff then
      test_queries ctx terrateam_config_change
      >>= fun res -> Abb.Future.return (Ok (CCOption.is_some res))
    else Abb.Future.return (Ok true)

  let eval ctx policies change_matches =
    Abbs_future_combinators.List_result.fold_left
      ~f:(fun (R.{ pass; deny } as r) change ->
        match
          CCList.find_opt
            (fun Policy.{ tag_query; _ } -> Terrat_change_match2.match_tag_query ~tag_query change)
            policies
        with
        | Some Policy.{ policy; _ } -> (
            let open Abbs_future_combinators.Infix_result_monad in
            test_queries ctx policy
            >>= function
            | Some _ -> Abb.Future.return (Ok R.{ r with pass = change :: pass })
            | None ->
                Abb.Future.return
                  (Ok
                     R.
                       {
                         r with
                         deny = Deny.{ change_match = change; policy = Some policy } :: deny;
                       }))
        | None ->
            Abb.Future.return
              (Ok R.{ r with deny = Deny.{ change_match = change; policy = None } :: deny }))
      ~init:R.{ pass = []; deny = [] }
      change_matches

  let eval_match_list ctx match_list =
    let open Abbs_future_combinators.Infix_result_monad in
    test_queries ctx match_list >>= fun res -> Abb.Future.return (Ok (CCOption.is_some res))
end
