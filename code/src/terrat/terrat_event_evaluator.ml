module Dir_set = CCSet.Make (CCString)
module String_set = CCSet.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

module Msg = struct
  module Apply_requirements = struct
    type t = {
      approved : bool option;
      merge_conflicts : bool option;
      status_checks : bool option;
      status_checks_failed : Terrat_commit_check.t list;
      approved_reviews : Terrat_pull_request_review.t list;
    }
  end

  type 'pull_request t =
    | Missing_plans of Terrat_change.Dirspace.t list
    | Dirspaces_owned_by_other_pull_request of 'pull_request Dirspace_map.t
    | Conflicting_work_manifests of 'pull_request Terrat_work_manifest.Existing_lite.t list
    | Repo_config_parse_failure of string
    | Repo_config_failure of string
    | Pull_request_not_appliable of ('pull_request * Apply_requirements.t)
    | Pull_request_not_mergeable of 'pull_request
    | Apply_no_matching_dirspaces
    | Plan_no_matching_dirspaces
    | Dest_branch_no_match of 'pull_request
    | Autoapply_running
    | Bad_glob of string
    | Access_control_denied of
        [ `All_dirspaces of Terrat_access_control.R.Deny.t list
        | `Dirspaces of Terrat_access_control.R.Deny.t list
        | `Invalid_query of string
        | `Lookup_err
        | `Terrateam_config_update of string list
        | `Terrateam_config_update_bad_query of string
        | `Unlock of string list
        ]
    | Unlock_success
end

module Op_class = struct
  type tf_mode =
    [ `Manual
    | `Auto
    ]
  [@@deriving show]

  type tf =
    [ `Apply of tf_mode
    | `Apply_autoapprove
    | `Apply_force
    | `Plan of tf_mode
    ]
  [@@deriving show]

  type t =
    | Terraform of tf
    | Pull_request of [ `Unlock ]
  [@@deriving show]

  let run_type_of_tf = function
    | `Apply `Auto -> Terrat_work_manifest.Run_type.Autoapply
    | `Apply `Manual | `Apply_force -> Terrat_work_manifest.Run_type.Apply
    | `Apply_autoapprove -> Terrat_work_manifest.Run_type.Unsafe_apply
    | `Plan `Auto -> Terrat_work_manifest.Run_type.Autoplan
    | `Plan `Manual -> Terrat_work_manifest.Run_type.Plan
end

module Event_type = struct
  type t =
    | Apply
    | Apply_autoapprove
    | Apply_force
    | Autoapply
    | Autoplan
    | Plan
    | Unlock
  [@@deriving show]

  (* Translate the event type to its operation class *)
  let to_op_class = function
    | Apply -> Op_class.Terraform (`Apply `Manual)
    | Apply_autoapprove -> Op_class.Terraform `Apply_autoapprove
    | Apply_force -> Op_class.Terraform `Apply_force
    | Autoapply -> Op_class.Terraform (`Apply `Auto)
    | Autoplan -> Op_class.Terraform (`Plan `Auto)
    | Plan -> Op_class.Terraform (`Plan `Manual)
    | Unlock -> Op_class.Pull_request `Unlock

  let to_string = function
    | Apply -> "apply"
    | Apply_autoapprove -> "apply_autoapprove"
    | Apply_force -> "apply_force"
    | Autoapply -> "autoapply"
    | Autoplan -> "autoplan"
    | Plan -> "plan"
    | Unlock -> "unlock"
end

module type S = sig
  module Event : sig
    type t

    val request_id : t -> string
    val event_type : t -> Event_type.t
    val tag_query : t -> Terrat_tag_set.t
    val default_branch : t -> string
    val user : t -> string
  end

  module Pull_request : sig
    type t

    val base_branch_name : t -> string
    val base_hash : t -> string
    val hash : t -> string
    val diff : t -> Terrat_change.Diff.t list
    val state : t -> Terrat_pull_request.State.t
    val passed_all_checks : t -> bool
    val mergeable : t -> bool option
    val is_draft_pr : t -> bool
    val branch_name : t -> string
  end

  module Access_control : Terrat_access_control.S

  val create_access_control_ctx : user:string -> Event.t -> Access_control.ctx

  val list_existing_dirs :
    Event.t -> Pull_request.t -> Dir_set.t -> (Dir_set.t, [> `Error ]) result Abb.Future.t

  val store_dirspaceflows :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_new_work_manifest :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t Terrat_work_manifest.New.t ->
    Terrat_access_control.R.Deny.t list ->
    (Pull_request.t Terrat_work_manifest.Existing_lite.t, [> `Error ]) result Abb.Future.t

  val store_pull_request :
    Pgsql_io.t -> Event.t -> Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val fetch_repo_config :
    Event.t ->
    Pull_request.t ->
    string ->
    ( Terrat_repo_config.Version_1.t,
      [> `Repo_config_parse_err of string | `Repo_config_err of string ] )
    result
    Abb.Future.t

  val fetch_pull_request : Event.t -> (Pull_request.t, [> `Error ]) result Abb.Future.t
  val fetch_tree : Event.t -> Pull_request.t -> (string list, [> `Error ]) result Abb.Future.t

  val fetch_commit_checks :
    Event.t -> Pull_request.t -> (Terrat_commit_check.t list, [> `Error ]) result Abb.Future.t

  val fetch_pull_request_reviews :
    Event.t ->
    Pull_request.t ->
    (Terrat_pull_request_review.t list, [> `Error ]) result Abb.Future.t

  val create_commit_checks :
    Event.t ->
    Pull_request.t ->
    Terrat_commit_check.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val get_commit_check_details_url : Event.t -> Pull_request.t -> string

  val query_conflicting_work_manifests_in_repo :
    Pgsql_io.t ->
    Event.t ->
    Op_class.tf ->
    (Pull_request.t Terrat_work_manifest.Existing_lite.t list, [> `Error ]) result Abb.Future.t

  val query_unapplied_dirspaces :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Pull_request.t Dirspace_map.t, [> `Error ]) result Abb.Future.t

  val query_pull_request_out_of_diff_applies :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val unlock_pull_request : Terrat_storage.t -> Event.t -> (unit, [> `Error ]) result Abb.Future.t
  val publish_msg : Event.t -> Pull_request.t Msg.t -> unit Abb.Future.t
end

let compute_matches ~repo_config ~tag_query ~out_of_change_applies ~diff ~repo_tree () =
  let open CCResult.Infix in
  Terrat_change_match.synthesize_dir_config ~file_list:repo_tree repo_config
  >>= fun dirs ->
  let all_matching_dirspaces =
    CCList.flat_map
      CCFun.(Terrat_change_match.of_dirspace dirs %> CCOption.to_list)
      out_of_change_applies
  in
  let all_matching_diff = Terrat_change_match.match_diff_list dirs diff in
  let all_matches = Terrat_change_match.merge_with_dedup all_matching_diff all_matching_dirspaces in
  let tag_query_matches =
    CCList.filter (Terrat_change_match.match_tag_query ~tag_query) all_matches
  in
  Ok (tag_query_matches, all_matches)

let match_tag_queries ~accessor ~changes queries =
  CCList.map
    (fun change ->
      ( change,
        CCList.find_idx
          (fun q -> Terrat_change_match.match_tag_query ~tag_query:(accessor q) change)
          queries ))
    changes

let dirspaceflows_of_changes repo_config changes =
  let workflows = CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows in
  CCList.map
    (fun (Terrat_change_match.{ dirspace; _ }, workflow) ->
      Terrat_change.Dirspaceflow.{ dirspace; workflow_idx = CCOption.map fst workflow })
    (match_tag_queries
       ~accessor:(fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
         Terrat_tag_set.of_string tag_query)
       ~changes
       workflows)

module Make (S : S) = struct
  let log_time event name t =
    Logs.info (fun m -> m "EVENT_EVALUATOR : %s : %s : %f" (S.Event.request_id event) name t)

  module Access_control = Terrat_access_control.Make (S.Access_control)

  module Access_control_engine = struct
    module Ac = Terrat_repo_config.Access_control
    module P = Terrat_repo_config.Access_control_policy

    let default_terrateam_config_update = [ "repo:admin" ]
    let default_plan = [ "*" ]
    let default_apply = [ "repo:maintain" ]
    let default_apply_force = [ "repo:admin" ]
    let default_apply_autoapprove = [ "repo:admin" ]
    let default_unlock = [ "*" ]
    let default_apply_with_superapproval = []
    let default_superapproval = []

    type t = {
      ctx : S.Access_control.ctx;
      event : S.Event.t;
      config : Terrat_repo_config.Access_control.t;
    }

    let make event repo_config =
      let ctx = S.create_access_control_ctx ~user:(S.Event.user event) event in
      let default = Terrat_repo_config.Access_control.make () in
      let config =
        CCOption.get_or ~default repo_config.Terrat_repo_config.Version_1.access_control
      in
      { ctx; event; config }

    let eval_repo_config t diff =
      let terrateam_config_update =
        CCOption.get_or ~default:default_terrateam_config_update t.config.Ac.terrateam_config_update
      in
      if t.config.Ac.enabled then
        Abbs_time_it.run (log_time t.event "ACCESS_CONTROL_EVAL_REPO_CONFIG") (fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Access_control.eval_repo_config t.ctx terrateam_config_update diff
            >>| function
            | true -> None
            | false -> Some terrateam_config_update)
      else (
        Logs.debug (fun m ->
            m "EVENT_EVALUATOR : %s : ACCESS_CONTROL_DISABLED" (S.Event.request_id t.event));
        Abb.Future.return (Ok None))

    let eval' t change_matches default selector =
      if t.config.Ac.enabled then
        let policies =
          match t.config.Ac.policies with
          | None ->
              (* If no policy is specified, then use the default *)
              [
                Terrat_access_control.Policy.
                  { tag_query = Terrat_tag_set.of_list []; policy = default };
              ]
          | Some policies ->
              (* Policies have been specified, but that doesn't mean the specific
                 operation that is being executed has a configuration.  So iterate
                 through and pluck out the specific configuration and take the
                 default if that configuration was not specified. *)
              policies
              |> CCList.map (fun (Terrat_repo_config.Access_control_policy.{ tag_query; _ } as p) ->
                     Terrat_access_control.Policy.
                       {
                         tag_query = Terrat_tag_set.of_string tag_query;
                         policy = CCOption.get_or ~default (selector p);
                       })
        in
        Abbs_time_it.run (log_time t.event "ACCESS_CONTROL_EVAL") (fun () ->
            Access_control.eval t.ctx policies change_matches)
      else (
        Logs.debug (fun m ->
            m "EVENT_EVALUATOR : %s : ACCESS_CONTROL_DISABLED" (S.Event.request_id t.event));
        Abb.Future.return (Ok Terrat_access_control.R.{ pass = change_matches; deny = [] }))

    let eval_superapproved t reviewers change_matches =
      let open Abbs_future_combinators.Infix_result_monad in
      (* First, let's see if this user can even apply any of the denied changes
         if there is a superapproval. If there isn't, we return the original
         response, otherwise we have to see if any of the changes have super
         approvals. *)
      eval'
        t
        change_matches
        default_apply_with_superapproval
        (fun P.{ apply_with_superapproval; _ } -> apply_with_superapproval)
      >>= function
      | Terrat_access_control.R.{ pass = _ :: _ as pass; deny } ->
          (* Now, of those that passed, let's see if any have been approved by a
             super approver.  To do this we'll iterate over the approvers. *)
          let pass_with_superapproval =
            pass
            |> CCList.map (fun (Terrat_change_match.{ dirspace; _ } as ch) -> (dirspace, ch))
            |> Dirspace_map.of_list
          in
          Abbs_future_combinators.List_result.fold_left
            ~f:(fun acc user ->
              let changes = acc |> Dirspace_map.to_list |> CCList.map snd in
              let ctx = S.create_access_control_ctx ~user t.event in
              let t' = { t with ctx } in
              eval' t' changes default_superapproval (fun P.{ superapproval; _ } -> superapproval)
              >>= fun Terrat_access_control.R.{ pass; _ } ->
              let acc =
                CCListLabels.fold_left
                  ~f:(fun acc Terrat_change_match.{ dirspace; _ } ->
                    Dirspace_map.remove dirspace acc)
                  ~init:acc
                  pass
              in
              Abb.Future.return (Ok acc))
            ~init:pass_with_superapproval
            reviewers
          >>= fun unapproved ->
          Abb.Future.return
            (Ok
               (Dirspace_map.fold
                  (fun k _ acc -> Dirspace_map.remove k acc)
                  unapproved
                  pass_with_superapproval))
      | _ ->
          Logs.debug (fun m ->
              m
                "EVENT_EVALUATOR : %s : ACCESS_CONTROL : NO_MATCHING_CHANGES_FOR_SUPERAPPROVAL"
                (S.Event.request_id t.event));
          Abb.Future.return (Ok Dirspace_map.empty)

    let eval_tf_operation t change_matches = function
      | `Plan -> eval' t change_matches default_plan (fun P.{ plan; _ } -> plan)
      | `Apply reviewers -> (
          let open Abbs_future_combinators.Infix_result_monad in
          eval' t change_matches default_apply (fun P.{ apply; _ } -> apply)
          >>= function
          | Terrat_access_control.R.{ pass; deny = _ :: _ as deny } ->
              (* If we have some denies, then let's see if any of them can be
                 applied with because of a super approver.  If not, we'll return
                 the original response. *)
              Logs.debug (fun m ->
                  m
                    "EVENT_EVALUATOR : %s : ACCESS_CONTROL : EVAL_SUPERAPPROVAL"
                    (S.Event.request_id t.event));
              let denied_change_matches =
                CCList.map
                  (fun Terrat_access_control.R.Deny.{ change_match; _ } -> change_match)
                  deny
              in
              eval_superapproved t reviewers denied_change_matches
              >>= fun superapproved ->
              let pass = pass @ (superapproved |> Dirspace_map.to_list |> CCList.map snd) in
              let deny =
                CCList.filter
                  (fun Terrat_access_control.R.Deny.
                         { change_match = Terrat_change_match.{ dirspace; _ }; _ } ->
                    not (Dirspace_map.mem dirspace superapproved))
                  deny
              in
              Abb.Future.return (Ok Terrat_access_control.R.{ pass; deny })
          | r -> Abb.Future.return (Ok r))
      | `Apply_force ->
          eval' t change_matches default_apply_force (fun P.{ apply_force; _ } -> apply_force)
      | `Apply_autoapprove ->
          eval' t change_matches default_apply_autoapprove (fun P.{ apply_autoapprove; _ } ->
              apply_autoapprove)

    let eval_pr_operation t = function
      | `Unlock ->
          if t.config.Ac.enabled then
            let match_list = CCOption.get_or ~default:default_unlock t.config.Ac.unlock in
            Abbs_time_it.run (log_time t.event "ACCESS_CONTROL_EVAL") (fun () ->
                let open Abbs_future_combinators.Infix_result_monad in
                Access_control.eval_match_list t.ctx match_list
                >>| function
                | true -> None
                | false -> Some match_list)
          else (
            Logs.debug (fun m ->
                m "EVENT_EVALUATOR : %s : ACCESS_CONTROL_DISABLED" (S.Event.request_id t.event));
            Abb.Future.return (Ok None))

    let plan_require_all_dirspace_access t = t.config.Ac.plan_require_all_dirspace_access
    let apply_require_all_dirspace_access t = t.config.Ac.apply_require_all_dirspace_access
  end

  let create_queued_commit_checks event run_type pull_request dirspaces =
    let details_url = S.get_commit_check_details_url event pull_request in
    let unified_run_type =
      let module Urt = Terrat_work_manifest.Unified_run_type in
      run_type |> Urt.of_run_type |> Urt.to_string
    in
    let aggregate =
      Terrat_commit_check.
        [
          make
            ~details_url
            ~description:"Queued"
            ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
            ~status:Status.Queued;
          make
            ~details_url
            ~description:"Queued"
            ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
            ~status:Status.Queued;
        ]
    in
    let dirspace_checks =
      CCList.map
        (fun Terrat_change.Dirspace.{ dir; workspace; _ } ->
          Terrat_commit_check.(
            make
              ~details_url
              ~description:"Queued"
              ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
              ~status:Status.Queued))
        dirspaces
    in
    aggregate @ dirspace_checks

  let can_apply_checkout_strategy repo_config pull_request =
    match
      ( S.Pull_request.mergeable pull_request,
        repo_config.Terrat_repo_config.Version_1.checkout_strategy )
    with
    | Some mergeable, "merge" -> mergeable
    | (Some _ | _), _ -> true

  let maybe_replace_old_commit_statuses event pull_request commit_checks =
    let open Abb.Future.Infix_monad in
    let replacement_commit_statuses =
      commit_checks
      |> CCList.filter (fun Terrat_commit_check.{ title; status; _ } ->
             (not Terrat_commit_check.Status.(equal status Completed))
             && (CCList.mem ~eq:CCString.equal title [ "terrateam plan"; "terrateam apply" ]
                || CCString.prefix ~pre:"terrateam plan " title
                || CCString.prefix ~pre:"terrateam apply " title))
      |> CCList.map (fun check -> Terrat_commit_check.{ check with status = Status.Completed })
    in
    S.create_commit_checks event pull_request replacement_commit_statuses
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error _ ->
        Logs.err (fun m ->
            m "EVENT_EVALUATOR : %s : FAILED_REPLACE_OLD_COMMIT_STATUSES" (S.Event.request_id event));
        Abb.Future.return ()

  let maybe_create_pending_apply event pull_request repo_config = function
    | [] ->
        (* No matches so don't make anything *)
        Abb.Future.return (Ok ())
    | all_matches ->
        let open Abb.Future.Infix_monad in
        let module Rc = Terrat_repo_config.Version_1 in
        let module Ar = Rc.Apply_requirements in
        let apply_requirements =
          CCOption.get_or ~default:(Rc.Apply_requirements.make ()) repo_config.Rc.apply_requirements
        in
        if apply_requirements.Ar.create_pending_apply_check then (
          Abbs_time_it.run (log_time event "FETCH_COMMIT_CHECKS") (fun () ->
              S.fetch_commit_checks event pull_request)
          >>= function
          | Ok commit_checks -> (
              Abb.Future.fork (maybe_replace_old_commit_statuses event pull_request commit_checks)
              >>= fun _ ->
              let details_url = S.get_commit_check_details_url event pull_request in
              let commit_check_titles =
                commit_checks
                |> CCList.map (fun Terrat_commit_check.{ title; _ } -> title)
                |> String_set.of_list
              in
              let missing_commit_checks =
                all_matches
                |> CCList.filter_map
                     (fun
                       Terrat_change_match.
                         {
                           dirspace = Terrat_change.Dirspace.{ dir; workspace };
                           when_modified = Terrat_repo_config.When_modified.{ autoapply; _ };
                           _;
                         }
                     ->
                       let name = Printf.sprintf "terrateam apply: %s %s" dir workspace in
                       if (not autoapply) && not (String_set.mem name commit_check_titles) then
                         Some
                           Terrat_commit_check.(
                             make
                               ~details_url
                               ~description:"Waiting"
                               ~title:(Printf.sprintf "terrateam apply: %s %s" dir workspace)
                               ~status:Status.Queued)
                       else None)
              in
              S.create_commit_checks event pull_request missing_commit_checks
              >>= function
              | Ok _ -> Abb.Future.return (Ok ())
              | Error `Error ->
                  Logs.err (fun m ->
                      m
                        "EVENT_EVALUATOR : %s : FAILED_CREATE_APPLY_CHECK"
                        (S.Event.request_id event));
                  Abb.Future.return (Ok ()))
          | Error _ as err ->
              Logs.err (fun m ->
                  m "EVENT_EVALUATOR : %s : FAILED_FETCH_COMMIT_CHECKS" (S.Event.request_id event));
              Abb.Future.return err)
        else Abb.Future.return (Ok ())

  let check_apply_requirements event pull_request repo_config =
    let module Rc = Terrat_repo_config.Version_1 in
    let module Ar = Rc.Apply_requirements in
    let open Abbs_future_combinators.Infix_result_monad in
    let apply_requirements =
      CCOption.get_or ~default:(Rc.Apply_requirements.make ()) repo_config.Rc.apply_requirements
    in
    let Ar.Checks.{ approved; merge_conflicts; status_checks } =
      CCOption.get_or ~default:(Ar.Checks.make ()) apply_requirements.Ar.checks
    in
    let approved = CCOption.get_or ~default:(Ar.Checks.Approved.make ()) approved in
    let merge_conflicts =
      CCOption.get_or ~default:(Ar.Checks.Merge_conflicts.make ()) merge_conflicts
    in
    let status_checks = CCOption.get_or ~default:(Ar.Checks.Status_checks.make ()) status_checks in
    Abbs_future_combinators.Infix_result_app.(
      (fun reviews commit_checks -> (reviews, commit_checks))
      <$> Abbs_time_it.run (log_time event "FETCH_APPROVED_TIME") (fun () ->
              S.fetch_pull_request_reviews event pull_request)
      <*> Abbs_time_it.run (log_time event "FETCH_COMMIT_CHECKS_TIME") (fun () ->
              S.fetch_commit_checks event pull_request))
    >>= fun (reviews, commit_checks) ->
    Abbs_future_combinators.to_result
      (Abb.Future.fork (maybe_replace_old_commit_statuses event pull_request commit_checks))
    >>= fun _ ->
    let approved_reviews =
      CCList.filter
        (function
          | Terrat_pull_request_review.{ status = Status.Approved; _ } -> true
          | _ -> false)
        reviews
    in
    let approved_result = CCList.length approved_reviews >= approved.Ar.Checks.Approved.count in
    let merge_result = CCOption.get_or ~default:false (S.Pull_request.mergeable pull_request) in
    let ignore_matching =
      CCOption.get_or ~default:[] status_checks.Ar.Checks.Status_checks.ignore_matching
    in
    (* Convert all patterns and ignore those that don't compile.  This eats
       errors.

       TODO: Improve handling errors here *)
    let ignore_matching_pats = CCList.filter_map Lua_pattern.of_string ignore_matching in
    (* Relevant checks exclude our terrateam checks, and also exclude any
       ignored patterns.  We check both if a pattern matches OR if there is an
       exact match with the string.  This is because someone might put in an
       invalid pattern (because secretly we are using Lua patterns underneath
       which have a slightly different syntax) *)
    let relevant_commit_checks =
      CCList.filter
        (fun Terrat_commit_check.{ title; _ } ->
          not
            (CCString.prefix ~pre:"terrateam apply:" title
            || CCString.prefix ~pre:"terrateam plan:" title
            || CCList.mem
                 ~eq:CCString.equal
                 title
                 [ "terrateam apply pre-hooks"; "terrateam apply post-hooks" ]
            || CCList.exists CCFun.(Lua_pattern.find title %> CCOption.is_some) ignore_matching_pats
            || CCList.exists (CCString.equal title) ignore_matching))
        commit_checks
    in
    let failed_commit_checks =
      CCList.filter
        (function
          | Terrat_commit_check.{ status = Status.Completed; _ } -> false
          | _ -> true)
        relevant_commit_checks
    in
    let all_commit_check_success = CCList.is_empty failed_commit_checks in
    let merged =
      let module St = Terrat_pull_request.State in
      match S.Pull_request.state pull_request with
      | St.Merged _ -> true
      | St.Open | St.Closed -> false
    in
    let apply_requirements =
      Msg.Apply_requirements.
        {
          approved = (if approved.Ar.Checks.Approved.enabled then Some approved_result else None);
          merge_conflicts =
            (if merge_conflicts.Ar.Checks.Merge_conflicts.enabled then Some merge_result else None);
          status_checks =
            (if status_checks.Ar.Checks.Status_checks.enabled then Some all_commit_check_success
            else None);
          status_checks_failed = failed_commit_checks;
          approved_reviews;
        }
    in
    (* If it's merged, nothing should stop an apply because it's already
       merged. *)
    let result =
      merged
      || ((not approved.Ar.Checks.Approved.enabled) || approved_result)
         && ((not merge_conflicts.Ar.Checks.Merge_conflicts.enabled) || merge_result)
         && ((not status_checks.Ar.Checks.Status_checks.enabled) || all_commit_check_success)
    in
    Logs.info (fun m ->
        m
          "EVENT_EVALUATOR : %s : APPLY_REQUIREMENTS_CHECKS : approved=%s merge_conflicts=%s \
           status_checks=%s"
          (S.Event.request_id event)
          (Bool.to_string approved.Ar.Checks.Approved.enabled)
          (Bool.to_string merge_conflicts.Ar.Checks.Merge_conflicts.enabled)
          (Bool.to_string status_checks.Ar.Checks.Status_checks.enabled));
    Logs.info (fun m ->
        m
          "EVENT_EVALUATOR : %s : APPLY_REQUIREMENTS_RESULT : approved=%s merge_check=%s \
           commit_check=%s merged=%s result=%s"
          (S.Event.request_id event)
          (Bool.to_string approved_result)
          (Bool.to_string merge_result)
          (Bool.to_string all_commit_check_success)
          (Bool.to_string merged)
          (Bool.to_string result));
    Abb.Future.return (Ok (result, apply_requirements))

  let create_and_store_work_manifest
      db
      repo_config
      event
      pull_request
      matches
      denied_dirspaces
      run_type =
    let open Abbs_future_combinators.Infix_result_monad in
    let dirspaceflows = dirspaceflows_of_changes repo_config matches in
    let dirspaces = CCList.map (fun Terrat_change_match.{ dirspace; _ } -> dirspace) matches in
    let work_manifest =
      Terrat_work_manifest.
        {
          base_hash = S.Pull_request.base_hash pull_request;
          changes = dirspaceflows;
          completed_at = None;
          created_at = ();
          hash = S.Pull_request.hash pull_request;
          id = ();
          pull_request;
          run_id = ();
          run_type;
          state = ();
          tag_query = S.Event.tag_query event;
        }
    in
    Abbs_time_it.run (log_time event "CREATE_WORK_MANIFEST") (fun () ->
        S.store_new_work_manifest db event work_manifest denied_dirspaces)
    >>= fun work_manifest ->
    Logs.info (fun m ->
        m
          "EVENT_EVALUATOR : %s : STORED_WORK_MANIFEST : %s"
          (S.Event.request_id event)
          (Uuidm.to_string work_manifest.Terrat_work_manifest.id));
    Abbs_time_it.run (log_time event "CREATE_COMMIT_CHECKS") (fun () ->
        S.create_commit_checks
          event
          pull_request
          (create_queued_commit_checks event run_type pull_request dirspaces))
    >>= fun () -> Abb.Future.return (Ok ())

  let process_plan' access_control db repo_config event pull_request tag_query_matches tf_mode =
    let module D = Terrat_access_control.R.Deny in
    let module Cm = Terrat_change_match in
    let open Abb.Future.Infix_monad in
    let matches =
      match tf_mode with
      | `Auto ->
          CCList.filter
            (fun Terrat_change_match.
                   {
                     when_modified =
                       Terrat_repo_config.When_modified.{ autoplan; autoplan_draft_pr; _ };
                     _;
                   } ->
              autoplan && ((not (S.Pull_request.is_draft_pr pull_request)) || autoplan_draft_pr))
            tag_query_matches
      | `Manual -> tag_query_matches
    in
    Access_control_engine.eval_tf_operation access_control matches `Plan
    >>= function
    | Ok Terrat_access_control.R.{ pass = []; deny = _ :: _ as deny }
      when not (Access_control_engine.plan_require_all_dirspace_access access_control) ->
        (* In this case all have been denied, but not all dirspaces must have
           access, however this is treated as special because no work will be done
           so a special message should be given to the usr. *)
        Abb.Future.return (Ok (Some (Msg.Access_control_denied (`All_dirspaces deny))))
    | Ok Terrat_access_control.R.{ pass; deny }
      when CCList.is_empty deny
           || not (Access_control_engine.plan_require_all_dirspace_access access_control) -> (
        (* All have passed or any that we do not require all to pass *)
        let matches = pass in
        match (tf_mode, matches) with
        | `Auto, [] ->
            Logs.info (fun m ->
                m
                  "EVENT_EVALUATOR : %s : NOOP : AUTOPLAN_NO_MATCHES : draft=%s"
                  (S.Event.request_id event)
                  (Bool.to_string (S.Pull_request.is_draft_pr pull_request)));
            Abb.Future.return (Ok None)
        | _, [] ->
            Logs.info (fun m ->
                m
                  "EVENT_EVALUATOR : %s : NOOP : PLAN_NO_MATCHING_DIRSPACES"
                  (S.Event.request_id event));
            Abb.Future.return (Ok (Some Msg.Plan_no_matching_dirspaces))
        | _, _ ->
            let open Abbs_future_combinators.Infix_result_monad in
            create_and_store_work_manifest
              db
              repo_config
              event
              pull_request
              matches
              deny
              (Op_class.run_type_of_tf (`Plan tf_mode))
            >>= fun () -> Abb.Future.return (Ok None))
    | Ok Terrat_access_control.R.{ deny; _ } ->
        Abb.Future.return (Ok (Some (Msg.Access_control_denied (`Dirspaces deny))))
    | Error `Error -> Abb.Future.return (Ok (Some (Msg.Access_control_denied `Lookup_err)))
    | Error (`Invalid_query query) ->
        Abb.Future.return (Ok (Some (Msg.Access_control_denied (`Invalid_query query))))

  let process_plan
      access_control
      db
      event
      tag_query_matches
      all_matches
      pull_request
      repo_config
      tf_mode =
    Abbs_future_combinators.Infix_result_app.(
      (fun _ plan_result -> plan_result)
      <$> maybe_create_pending_apply event pull_request repo_config all_matches
      <*> process_plan' access_control db repo_config event pull_request tag_query_matches tf_mode)

  let process_apply'
      db
      event
      matches
      all_match_dirspaceflows
      pull_request
      repo_config
      operation
      denies =
    let module D = Terrat_access_control.R.Deny in
    let module Cm = Terrat_change_match in
    let open Abbs_future_combinators.Infix_result_monad in
    match (operation, matches) with
    | `Apply `Auto, [] ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : NOOP : AUTOAPPLY_NO_MATCHES" (S.Event.request_id event));
        Abb.Future.return (Ok None)
    | _, [] ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : NOOP : APPLY_NO_MATCHING_DIRSPACES" (S.Event.request_id event));
        Abb.Future.return (Ok (Some Msg.Apply_no_matching_dirspaces))
    | _, _ -> (
        Abbs_time_it.run (log_time event "QUERY_DIRSPACES_OWNED_BY_OTHER_PRS") (fun () ->
            S.query_dirspaces_owned_by_other_pull_requests
              db
              event
              pull_request
              (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows))
        >>= function
        | dirspaces when Dirspace_map.is_empty dirspaces && operation = `Apply_autoapprove -> (
            create_and_store_work_manifest
              db
              repo_config
              event
              pull_request
              matches
              denies
              (Op_class.run_type_of_tf operation)
            >>= function
            | () when operation = `Apply `Auto ->
                Abb.Future.return (Ok (Some Msg.Autoapply_running))
            | () -> Abb.Future.return (Ok None))
        | dirspaces when Dirspace_map.is_empty dirspaces -> (
            (* None of the dirspaces are owned by another PR, we can proceed *)
            Abbs_time_it.run (log_time event "QUERY_DIRSPACES_WITHOUT_VALID_PLANS") (fun () ->
                S.query_dirspaces_without_valid_plans
                  db
                  event
                  pull_request
                  (CCList.map (fun Terrat_change_match.{ dirspace; _ } -> dirspace) matches))
            >>= function
            | [] -> (
                (* All are ready to be applied *)
                create_and_store_work_manifest
                  db
                  repo_config
                  event
                  pull_request
                  matches
                  denies
                  (Op_class.run_type_of_tf operation)
                >>= function
                | () when operation = `Apply `Auto ->
                    Abb.Future.return (Ok (Some Msg.Autoapply_running))
                | () -> Abb.Future.return (Ok None))
            | dirspaces ->
                (* Some are missing plans *)
                Abb.Future.return (Ok (Some (Msg.Missing_plans dirspaces))))
        | dirspaces ->
            (* Some are owned by another PR, abort *)
            Abb.Future.return (Ok (Some (Msg.Dirspaces_owned_by_other_pull_request dirspaces))))

  let process_apply
      access_control
      db
      event
      tag_query_matches
      all_match_dirspaceflows
      pull_request
      repo_config
      operation =
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_time_it.run (log_time event "MISSING_APPLIED_DIRSPACES") (fun () ->
        S.query_unapplied_dirspaces db event pull_request)
    >>= fun missing_dirspaces ->
    (* Filter only those missing *)
    let tag_query_matches =
      CCList.filter
        (fun Terrat_change_match.{ dirspace; _ } ->
          CCList.mem ~eq:Terrat_change.Dirspace.equal dirspace missing_dirspaces)
        tag_query_matches
    in
    (* To perform an apply we need:

       1. Plans for all of the dirspaces we are going to run.  This
       also means that the plan also has happened after any of the
       most recent applies to that dirspace.

       2. Make sure no other pull requests own the any of the
       dirspaces that this pull request touches. *)
    let matches =
      match operation with
      | `Apply `Auto ->
          CCList.filter
            (fun Terrat_change_match.
                   { when_modified = Terrat_repo_config.When_modified.{ autoapply; _ }; _ } ->
              autoapply)
            tag_query_matches
      | `Apply `Manual | `Apply_autoapprove | `Apply_force -> tag_query_matches
    in
    Abbs_time_it.run (log_time event "CHECK_APPLY_REQUIREMENTS") (fun () ->
        check_apply_requirements event pull_request repo_config)
    >>= fun (passed_apply_requirements, apply_requirements_results) ->
    let access_control_run_type =
      match operation with
      | `Apply _ ->
          `Apply
            (CCList.flat_map
               (function
                 | Terrat_pull_request_review.{ user = Some user; _ } -> [ user ]
                 | _ -> [])
               apply_requirements_results.Msg.Apply_requirements.approved_reviews)
      | (`Apply_autoapprove | `Apply_force) as op -> op
    in
    let open Abb.Future.Infix_monad in
    Access_control_engine.eval_tf_operation access_control matches access_control_run_type
    >>= function
    | Ok access_control_result -> (
        match (operation, access_control_result) with
        | (`Apply _ | `Apply_autoapprove), _ when not passed_apply_requirements ->
            Logs.info (fun m ->
                m "EVENT_EVALUATOR : %s : PR_NOT_APPLIABLE" (S.Event.request_id event));
            Abb.Future.return
              (Ok (Some (Msg.Pull_request_not_appliable (pull_request, apply_requirements_results))))
        | _, Terrat_access_control.R.{ pass = []; deny = _ :: _ as deny }
          when not (Access_control_engine.apply_require_all_dirspace_access access_control) ->
            (* In this case all have been denied, but not all dirspaces must have
               access, however this is treated as special because no work will be done
               so a special message should be given to the usr. *)
            Abb.Future.return (Ok (Some (Msg.Access_control_denied (`All_dirspaces deny))))
        | _, Terrat_access_control.R.{ pass; deny }
          when CCList.is_empty deny
               || not (Access_control_engine.apply_require_all_dirspace_access access_control) ->
            (* All have passed or any that we do not require all to pass *)
            let matches = pass in
            process_apply'
              db
              event
              matches
              all_match_dirspaceflows
              pull_request
              repo_config
              operation
              deny
        | _, Terrat_access_control.R.{ deny; _ } ->
            Abb.Future.return (Ok (Some (Msg.Access_control_denied (`Dirspaces deny)))))
    | Error `Error -> Abb.Future.return (Ok (Some (Msg.Access_control_denied `Lookup_err)))
    | Error (`Invalid_query query) ->
        Abb.Future.return (Ok (Some (Msg.Access_control_denied (`Invalid_query query))))

  let exec_event access_control storage event pull_request repo_config repo_tree operation =
    let open Abbs_future_combinators.Infix_result_monad in
    Logs.info (fun m ->
        m
          "EVENT_EVALUATOR : %s : PULL_REQUEST : base_sha=%s : sha=%s"
          (S.Event.request_id event)
          (S.Pull_request.base_hash pull_request)
          (S.Pull_request.hash pull_request));
    Logs.info (fun m ->
        m
          "EVENT_EVALUATOR : %s : PULL_REQUEST : NUM_DIFF : %d"
          (S.Event.request_id event)
          (CCList.length (S.Pull_request.diff pull_request)));
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.tx db ~f:(fun () ->
            Abbs_time_it.run (log_time event "QUERY_CONFLICTING_WORK_MANIFESTS") (fun () ->
                S.query_conflicting_work_manifests_in_repo db event operation)
            >>= function
            | [] -> (
                (* Collect any changes that have been applied outside of the current
                   state of the PR.  For example, we made a change to dir1 and dir2,
                   applied dir1, then we updated our PR to revert dir1, we would
                   want to be able to plan and apply dir1 again even though it
                   doesn't look like dir1 changes. *)
                Abbs_time_it.run (log_time event "QUERY_OUT_OF_DIFF_APPLIES") (fun () ->
                    S.query_pull_request_out_of_diff_applies db event pull_request)
                >>= fun out_of_change_applies ->
                Abb.Future.return
                  (compute_matches
                     ~repo_config
                     ~tag_query:(S.Event.tag_query event)
                     ~out_of_change_applies
                     ~diff:(S.Pull_request.diff pull_request)
                     ~repo_tree
                     ())
                >>= fun (tag_query_matches, all_matches) ->
                let dirs =
                  all_matches
                  |> CCList.map
                       (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ }
                       -> dir)
                  |> Dir_set.of_list
                in
                Abbs_time_it.run (log_time event "LIST_EXISTING_DIRS") (fun () ->
                    S.list_existing_dirs event pull_request dirs)
                >>= fun existing_dirs ->
                let missing_dirs = Dir_set.diff dirs existing_dirs in
                Logs.info (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : MISSING_DIRS : %d"
                      (S.Event.request_id event)
                      (Dir_set.cardinal missing_dirs));
                let all_match_dirspaces =
                  all_matches
                  |> CCList.filter
                       (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ }
                       -> Dir_set.mem dir existing_dirs)
                in
                let tag_query_matches =
                  tag_query_matches
                  |> CCList.filter
                       (fun Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ }
                       -> Dir_set.mem dir existing_dirs)
                in
                let all_match_dirspaceflows =
                  dirspaceflows_of_changes repo_config all_match_dirspaces
                in
                Abbs_time_it.run (log_time event "STORE_DIRSPACEFLOWS") (fun () ->
                    S.store_dirspaceflows db event pull_request all_match_dirspaceflows)
                >>= fun () ->
                match operation with
                | `Plan tf_mode ->
                    Abbs_time_it.run (log_time event "PROCESS_PLAN") (fun () ->
                        process_plan
                          access_control
                          db
                          event
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          tf_mode)
                | `Apply tf_mode ->
                    Abbs_time_it.run (log_time event "PROCESS_APPLY") (fun () ->
                        process_apply
                          access_control
                          db
                          event
                          tag_query_matches
                          all_match_dirspaceflows
                          pull_request
                          repo_config
                          (`Apply tf_mode))
                | `Apply_autoapprove ->
                    Abbs_time_it.run (log_time event "PROCESS_APPLY_AUTOAPPROVE") (fun () ->
                        process_apply
                          access_control
                          db
                          event
                          tag_query_matches
                          all_match_dirspaceflows
                          pull_request
                          repo_config
                          `Apply_autoapprove)
                | `Apply_force ->
                    Abbs_time_it.run (log_time event "PROCESS_APPLY_FORCE") (fun () ->
                        process_apply
                          access_control
                          db
                          event
                          tag_query_matches
                          all_match_dirspaceflows
                          pull_request
                          repo_config
                          `Apply_force))
            | wms -> Abb.Future.return (Ok (Some (Msg.Conflicting_work_manifests wms)))))

  (* Turn a glob into lua pattern for checking.  We escape all lua pattern
     special characters "().%+-?[^$", turn * into ".*", and wrap the whole thing
     in ^ and $ to make it a complete string match. *)
  let pattern_of_glob s =
    let len = CCString.length s in
    let b = Buffer.create len in
    Buffer.add_char b '^';
    for i = 0 to len - 1 do
      match CCString.get s i with
      | '*' -> Buffer.add_string b ".*"
      | ('(' | ')' | '.' | '%' | '+' | '-' | '?' | '[' | '^' | '$') as c ->
          Buffer.add_char b '%';
          Buffer.add_char b c
      | c -> Buffer.add_char b c
    done;
    Buffer.add_char b '$';
    let pattern = Buffer.contents b in
    CCOption.get_exn_or ("pattern_glob " ^ s ^ " " ^ pattern) (Lua_pattern.of_string pattern)

  (* Get a destination branch from the destination branch configuration and
     normalize it all on the Destination_branch_object type so it's easier to
     work with. *)
  let get_destination_branch =
    let module D = Terrat_repo_config.Version_1.Destination_branches.Items in
    let module O = Terrat_repo_config.Destination_branch_object in
    function
    | D.Destination_branch_name branch -> O.make ~branch ()
    | D.Destination_branch_object obj -> obj

  let rec eval_destination_branch_match dest_branch source_branch =
    let module Obj = Terrat_repo_config.Destination_branch_object in
    function
    | [] -> Error `No_matching_dest_branch
    | Obj.{ branch; source_branches } :: valid_branches -> (
        let branch_glob = pattern_of_glob (CCString.lowercase_ascii branch) in
        match Lua_pattern.find dest_branch branch_glob with
        | Some _ ->
            (* Partition the source branches into the not patterns and the
               positive patterns. *)
            let not_branches, branches =
              CCList.partition
                (CCString.prefix ~pre:"!")
                (CCOption.get_or ~default:[ "*" ] source_branches)
            in
            (* Remove the exclamation point from the beginning as it's not
               actually part of the pattern. *)
            let not_branch_globs =
              CCList.map
                CCFun.(CCString.drop 1 %> CCString.lowercase_ascii %> pattern_of_glob)
                not_branches
            in
            let branch_globs =
              let branches =
                (* If there are not-branch globs, but branch globs is empty,
                   that implicitly means match anything on the positive branch.
                   If not-branches are empty then take what is in branches,
                   which could be nothing. *)
                match (not_branch_globs, branches) with
                | _ :: _, [] -> [ "*" ]
                | _, branches -> branches
              in
              CCList.map CCFun.(CCString.lowercase_ascii %> pattern_of_glob) branches
            in
            (* The not patterns are an "and", as in success for the not patterns
               is that all of them do not match.

               The positive matches, however, are if any of them match. *)
            if
              CCList.for_all
                CCFun.(Lua_pattern.find source_branch %> CCOption.is_none)
                not_branch_globs
              && CCList.exists
                   CCFun.(Lua_pattern.find source_branch %> CCOption.is_some)
                   branch_globs
            then Ok ()
            else Error `No_matching_source_branch
        | None ->
            (* If the dest branch doesn't match this branch, then try the next *)
            eval_destination_branch_match dest_branch source_branch valid_branches)

  (* Given a pull request and a repo configuration, validate that the
     destination branch and the source branch are valid.  Everything is
     converted to lowercase. *)
  let is_valid_destination_branch event pull_request repo_config =
    let module Rc = Terrat_repo_config_version_1 in
    let module Obj = Terrat_repo_config.Destination_branch_object in
    let valid_branches =
      CCOption.map_or
        ~default:[ Obj.make ~branch:(S.Event.default_branch event) () ]
        (CCList.map get_destination_branch)
        repo_config.Rc.destination_branches
    in
    let dest_branch = CCString.lowercase_ascii (S.Pull_request.base_branch_name pull_request) in
    let source_branch = CCString.lowercase_ascii (S.Pull_request.branch_name pull_request) in
    eval_destination_branch_match dest_branch source_branch valid_branches

  let handle_branches_error event pull_request msg_fragment =
    match S.Event.event_type event with
    | Event_type.Autoplan | Event_type.Autoapply ->
        Logs.info (fun m ->
            m
              "EVENT_EVALUATOR : %s : %s_BRANCH_NOT_VALID_BRANCH"
              (S.Event.request_id event)
              msg_fragment);
        Abb.Future.return (Ok None)
    | Event_type.Plan
    | Event_type.Apply
    | Event_type.Apply_autoapprove
    | Event_type.Apply_force
    | Event_type.Unlock ->
        Logs.info (fun m ->
            m
              "EVENT_EVALUATOR : %s : %s_BRANCH_NOT_VALID_BRANCH_EXPLICIT"
              (S.Event.request_id event)
              msg_fragment);
        Abb.Future.return (Ok (Some (Msg.Dest_branch_no_match pull_request)))

  let fetch_default_repo_config event pull_request =
    let open Abbs_future_combinators.Infix_result_monad in
    S.fetch_repo_config event pull_request (S.Event.default_branch event)
    >>| fun repo_default_config ->
    match is_valid_destination_branch event pull_request repo_default_config with
    | Ok () -> Ok repo_default_config
    | Error _ as err -> err

  let run' storage event =
    let module Run_type = Terrat_work_manifest.Run_type in
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_time_it.run (log_time event "FETCHING_PULL_REQUEST") (fun () -> S.fetch_pull_request event)
    >>= fun pull_request ->
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Abbs_time_it.run (log_time event "STORE_PULL_REQUEST") (fun () ->
            S.store_pull_request db event pull_request))
    >>= fun () ->
    Abbs_future_combinators.Infix_result_app.(
      (fun repo_config repo_default_config repo_tree ->
        (repo_config, repo_default_config, repo_tree))
      <$> Abbs_time_it.run (log_time event "FETCHING_REPO_CONFIG") (fun () ->
              S.fetch_repo_config event pull_request (S.Pull_request.hash pull_request))
      <*> Abbs_time_it.run (log_time event "FETCHING_DEST_REPO_CONFIG") (fun () ->
              fetch_default_repo_config event pull_request)
      <*> Abbs_time_it.run (log_time event "FETCHING_REPO_TREE") (fun () ->
              S.fetch_tree event pull_request))
    >>= fun (repo_config, repo_default_config, repo_tree) ->
    match repo_default_config with
    | Ok repo_default_config ->
        if repo_default_config.Terrat_repo_config.Version_1.enabled then
          let access_control = Access_control_engine.make event repo_default_config in
          match Event_type.to_op_class (S.Event.event_type event) with
          | Op_class.Pull_request `Unlock -> (
              let open Abb.Future.Infix_monad in
              Access_control_engine.eval_pr_operation access_control `Unlock
              >>= function
              | Ok None ->
                  let open Abbs_future_combinators.Infix_result_monad in
                  S.unlock_pull_request storage event
                  >>= fun () -> Abb.Future.return (Ok (Some Msg.Unlock_success))
              | Ok (Some match_list) ->
                  Abb.Future.return (Ok (Some (Msg.Access_control_denied (`Unlock match_list))))
              | Error `Error ->
                  Abb.Future.return (Ok (Some (Msg.Access_control_denied `Lookup_err)))
              | Error (`Invalid_query query) ->
                  Abb.Future.return
                    (Ok
                       (Some (Msg.Access_control_denied (`Terrateam_config_update_bad_query query))))
              )
          | Op_class.Terraform operation -> (
              match S.Pull_request.state pull_request with
              | Terrat_pull_request.State.(Open | Merged _)
                when can_apply_checkout_strategy repo_config pull_request -> (
                  let open Abb.Future.Infix_monad in
                  Access_control_engine.eval_repo_config
                    access_control
                    (S.Pull_request.diff pull_request)
                  >>= function
                  | Ok None ->
                      exec_event
                        access_control
                        storage
                        event
                        pull_request
                        repo_config
                        repo_tree
                        operation
                  | Ok (Some match_list) ->
                      Abb.Future.return
                        (Ok (Some (Msg.Access_control_denied (`Terrateam_config_update match_list))))
                  | Error `Error ->
                      Abb.Future.return (Ok (Some (Msg.Access_control_denied `Lookup_err)))
                  | Error (`Invalid_query query) ->
                      Abb.Future.return
                        (Ok
                           (Some
                              (Msg.Access_control_denied (`Terrateam_config_update_bad_query query))))
                  )
              | Terrat_pull_request.State.(Open | Merged _) ->
                  (* Cannot apply checkout strategy *)
                  Logs.info (fun m ->
                      m
                        "EVENT_EVALUATOR : %s : CANNOT_APPLY_CHECKOUT_STRATEGY"
                        (S.Event.request_id event));
                  Abb.Future.return (Ok (Some (Msg.Pull_request_not_mergeable pull_request)))
              | Terrat_pull_request.State.Closed ->
                  Logs.info (fun m ->
                      m "EVENT_EVALUATOR : %s : NOOP : PR_CLOSED" (S.Event.request_id event));
                  Pgsql_pool.with_conn storage ~f:(fun db ->
                      Abbs_time_it.run (log_time event "STORE_PULL_REQUEST") (fun () ->
                          S.store_pull_request db event pull_request))
                  >>= fun () -> Abb.Future.return (Ok None))
        else (
          Logs.info (fun m ->
              m "EVENT_EVALUATOR : %s : NOOP : REPO_CONFIG_DISABLED" (S.Event.request_id event));
          Abb.Future.return (Ok None))
    | Error `No_matching_dest_branch -> handle_branches_error event pull_request "DEST"
    | Error `No_matching_source_branch -> handle_branches_error event pull_request "SOURCE"

  let run storage event =
    Abb.Future.await_bind
      (function
        | `Det v -> (
            match v with
            | Ok (Some msg) ->
                Abbs_time_it.run (log_time event "PUBLISH_MSG") (fun () -> S.publish_msg event msg)
            | Ok None -> Abb.Future.return ()
            | Error (`Bad_glob s) ->
                Logs.err (fun m ->
                    m "EVENT_EVALUATOR : %s : BAD_GLOB : %s" (S.Event.request_id event) s);
                S.publish_msg event (Msg.Bad_glob s)
            | Error (`Repo_config_parse_err err) ->
                Logs.info (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : REPO_CONFIG_PARSE_ERR : %s"
                      (S.Event.request_id event)
                      err);
                S.publish_msg event (Msg.Repo_config_parse_failure err)
            | Error (`Repo_config_err err) ->
                Logs.info (fun m ->
                    m "EVENT_EVALUATOR : %s : REPO_CONFIG_ERR : %s" (S.Event.request_id event) err);
                S.publish_msg event (Msg.Repo_config_failure err)
            | Error `Error ->
                Logs.err (fun m ->
                    m "EVENT_EVALUATOR : %s : ERROR : ERROR" (S.Event.request_id event));
                Abb.Future.return ()
            | Error (#Pgsql_pool.err as err) ->
                Logs.err (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : ERROR : %s"
                      (S.Event.request_id event)
                      (Pgsql_pool.show_err err));
                Abb.Future.return ()
            | Error (#Pgsql_io.err as err) ->
                Logs.err (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : ERROR : %s"
                      (S.Event.request_id event)
                      (Pgsql_io.show_err err));
                Abb.Future.return ())
        | `Aborted ->
            Logs.err (fun m -> m "EVENT_EVALUATOR : %s : ABORTED" (S.Event.request_id event));
            Abb.Future.return ()
        | `Exn (exn, bt_opt) ->
            Logs.err (fun m ->
                m
                  "EVENT_EVALUATOR : %s : EXN : %s : %s"
                  (S.Event.request_id event)
                  (Printexc.to_string exn)
                  (CCOption.map_or ~default:"" Printexc.raw_backtrace_to_string bt_opt));
            Abb.Future.return ())
      (run' storage event)
end
