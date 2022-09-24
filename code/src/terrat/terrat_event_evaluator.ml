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
end

module type S = sig
  module Event : sig
    type t

    val request_id : t -> string
    val run_type : t -> Terrat_work_manifest.Run_type.t
    val tag_query : t -> Terrat_tag_set.t
    val default_branch : t -> string
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

  val publish_msg : Event.t -> Pull_request.t Msg.t -> unit Abb.Future.t
end

let unified_run_type =
  let open Terrat_work_manifest.Run_type in
  function
  | Autoplan -> `Plan `Auto
  | Plan -> `Plan `Manual
  | Autoapply -> `Apply `Auto
  | Apply -> `Apply `Manual
  | Unsafe_apply -> `Unsafe_apply

let compute_matches ~repo_config ~tag_query ~out_of_change_applies ~diff ~repo_tree () =
  let open CCResult.Infix in
  let all_matching_dirspaces =
    Terrat_change_matcher.map_dirspace ~filelist:repo_tree repo_config out_of_change_applies
  in
  Terrat_change_matcher.match_diff ~filelist:repo_tree repo_config diff
  >>= fun all_matching_diff ->
  let all_matches = Terrat_change_matcher.merge_dedup all_matching_dirspaces all_matching_diff in
  let all_match_dirspaceflows = CCList.map Terrat_change_matcher.dirspaceflow all_matches in
  let tag_query_matches =
    Terrat_change_matcher.map_dirspace
      ~tag_query
      ~filelist:repo_tree
      repo_config
      (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows)
  in
  Ok (tag_query_matches, all_matches)

module Make (S : S) = struct
  let create_queued_commit_checks event pull_request dirspaces =
    let details_url = S.get_commit_check_details_url event pull_request in
    let unified_run_type =
      let module Urt = Terrat_work_manifest.Unified_run_type in
      event |> S.Event.run_type |> Urt.of_run_type |> Urt.to_string
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
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "EVENT_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %f" (S.Event.request_id event) t))
            (fun () -> S.fetch_commit_checks event pull_request)
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
                       Terrat_change_matcher.
                         {
                           dirspaceflow =
                             Terrat_change.
                               { Dirspaceflow.dirspace = Dirspace.{ dir; workspace }; _ };
                           when_modified = Terrat_repo_config.When_modified.{ autoapply; _ };
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
      <$> Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "EVENT_EVALUATOR : %s : FETCH_APPROVED_TIME : %f" (S.Event.request_id event) t))
            (fun () -> S.fetch_pull_request_reviews event pull_request)
      <*> Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m
                    "EVENT_EVALUATOR : %s : FETCH_COMMIT_CHECKS_TIME : %f"
                    (S.Event.request_id event)
                    t))
            (fun () -> S.fetch_commit_checks event pull_request))
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

  let create_and_store_work_manifest db event pull_request matches =
    let open Abbs_future_combinators.Infix_result_monad in
    let dirspaceflows = CCList.map Terrat_change_matcher.dirspaceflow matches in
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
          run_type = S.Event.run_type event;
          state = ();
          tag_query = S.Event.tag_query event;
        }
    in
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : CREATE_WORK_MANIFEST : %f" (S.Event.request_id event) t))
      (fun () -> S.store_new_work_manifest db event work_manifest)
    >>= fun _ ->
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : CREATE_COMMIT_CHECKS : %f" (S.Event.request_id event) t))
      (fun () ->
        S.create_commit_checks
          event
          pull_request
          (create_queued_commit_checks
             event
             pull_request
             (CCList.map (fun dsf -> dsf.Terrat_change.Dirspaceflow.dirspace) dirspaceflows)))
    >>= fun () -> Abb.Future.return (Ok ())

  let process_plan' db event pull_request tag_query_matches run_source_type =
    let matches =
      match run_source_type with
      | `Auto ->
          CCList.filter
            (fun {
                   Terrat_change_matcher.when_modified =
                     Terrat_repo_config.When_modified.{ autoplan; autoplan_draft_pr; _ };
                   _;
                 } ->
              autoplan && ((not (S.Pull_request.is_draft_pr pull_request)) || autoplan_draft_pr))
            tag_query_matches
      | `Manual -> tag_query_matches
    in
    match (S.Event.run_type event, matches) with
    | Terrat_work_manifest.Run_type.Autoplan, [] ->
        Logs.info (fun m ->
            m
              "EVENT_EVALUATOR : %s : NOOP : AUTOPLAN_NO_MATCHES : draft=%s"
              (S.Event.request_id event)
              (Bool.to_string (S.Pull_request.is_draft_pr pull_request)));
        Abb.Future.return (Ok None)
    | _, [] ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : NOOP : PLAN_NO_MATCHING_DIRSPACES" (S.Event.request_id event));
        Abb.Future.return (Ok (Some Msg.Plan_no_matching_dirspaces))
    | _, _ ->
        let open Abbs_future_combinators.Infix_result_monad in
        create_and_store_work_manifest db event pull_request matches
        >>= fun () -> Abb.Future.return (Ok None)

  let process_plan db event tag_query_matches all_matches pull_request repo_config run_source_type =
    Abbs_future_combinators.Infix_result_app.(
      (fun _ plan_result -> plan_result)
      <$> maybe_create_pending_apply event pull_request repo_config all_matches
      <*> process_plan' db event pull_request tag_query_matches run_source_type)

  let process_apply
      db
      event
      tag_query_matches
      all_match_dirspaceflows
      pull_request
      repo_config
      run_type
      run_source_type =
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : CHECK_APPLY_REQUIREMENTS : %f" (S.Event.request_id event) t))
      (fun () -> check_apply_requirements event pull_request repo_config)
    >>= function
    | true, _ -> (
        Abbs_time_it.run
          (fun t ->
            Logs.info (fun m ->
                m
                  "EVENT_EVALUATOR : %s : MISSING_APPLIED_DIRSPACES : %f"
                  (S.Event.request_id event)
                  t))
          (fun () -> S.query_unapplied_dirspaces db event pull_request)
        >>= fun missing_dirspaces ->
        (* Filter only those missing *)
        let tag_query_matches =
          CCList.filter
            (fun Terrat_change_matcher.
                   { dirspaceflow = Terrat_change.Dirspaceflow.{ dirspace; _ }; _ } ->
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
          match run_source_type with
          | `Auto ->
              CCList.filter
                (fun {
                       Terrat_change_matcher.when_modified =
                         Terrat_repo_config.When_modified.{ autoapply; _ };
                       _;
                     } -> autoapply)
                tag_query_matches
          | `Manual -> tag_query_matches
        in
        match (S.Event.run_type event, matches) with
        | Terrat_work_manifest.Run_type.Autoapply, [] ->
            Logs.info (fun m ->
                m "EVENT_EVALUATOR : %s : NOOP : AUTOAPPLY_NO_MATCHES" (S.Event.request_id event));
            Abb.Future.return (Ok None)
        | _, [] ->
            Logs.info (fun m ->
                m
                  "EVENT_EVALUATOR : %s : NOOP : APPLY_NO_MATCHING_DIRSPACES"
                  (S.Event.request_id event));
            Abb.Future.return (Ok (Some Msg.Apply_no_matching_dirspaces))
        | _, _ -> (
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : QUERY_DIRSPACES_OWNED_BY_OTHER_PRS : %f"
                      (S.Event.request_id event)
                      t))
              (fun () ->
                S.query_dirspaces_owned_by_other_pull_requests
                  db
                  event
                  pull_request
                  (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows))
            >>= function
            | dirspaces when Dirspace_map.is_empty dirspaces && run_type = `Unsafe_apply -> (
                create_and_store_work_manifest db event pull_request matches
                >>= function
                | () when S.Event.run_type event = Terrat_work_manifest.Run_type.Autoapply ->
                    Abb.Future.return (Ok (Some Msg.Autoapply_running))
                | () -> Abb.Future.return (Ok None))
            | dirspaces when Dirspace_map.is_empty dirspaces -> (
                (* None of the dirspaces are owned by another PR, we can proceed *)
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m
                          "EVENT_EVALUATOR : %s : QUERY_DIRSPACES_WITHOUT_VALID_PLANS : %f"
                          (S.Event.request_id event)
                          t))
                  (fun () ->
                    S.query_dirspaces_without_valid_plans
                      db
                      event
                      pull_request
                      (CCList.map
                         CCFun.(
                           Terrat_change_matcher.dirspaceflow
                           %> Terrat_change.Dirspaceflow.to_dirspace)
                         matches))
                >>= function
                | [] -> (
                    (* All are ready to be applied *)
                    create_and_store_work_manifest db event pull_request matches
                    >>= function
                    | () when S.Event.run_type event = Terrat_work_manifest.Run_type.Autoapply ->
                        Abb.Future.return (Ok (Some Msg.Autoapply_running))
                    | () -> Abb.Future.return (Ok None))
                | dirspaces ->
                    (* Some are missing plans *)
                    Abb.Future.return (Ok (Some (Msg.Missing_plans dirspaces))))
            | dirspaces ->
                (* Some are owned by another PR, abort *)
                Abb.Future.return (Ok (Some (Msg.Dirspaces_owned_by_other_pull_request dirspaces))))
        )
    | false, apply_requirements ->
        Logs.info (fun m -> m "EVENT_EVALUATOR : %s : PR_NOT_APPLIABLE" (S.Event.request_id event));
        Abb.Future.return
          (Ok (Some (Msg.Pull_request_not_appliable (pull_request, apply_requirements))))

  let exec_event storage event pull_request repo_config repo_tree =
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
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "EVENT_EVALUATOR : %s : STORE_PULL_REQUEST : %f" (S.Event.request_id event) t))
              (fun () -> S.store_pull_request db event pull_request)
            >>= fun () ->
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : QUERY_CONFLICTING_WORK_MANIFESTS : %f"
                      (S.Event.request_id event)
                      t))
              (fun () -> S.query_conflicting_work_manifests_in_repo db event)
            >>= function
            | [] -> (
                (* Collect any changes that have been applied outside of the current
                   state of the PR.  For example, we made a change to dir1 and dir2,
                   applied dir1, then we updated our PR to revert dir1, we would
                   want to be able to plan and apply dir1 again even though it
                   doesn't look like dir1 changes. *)
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m
                          "EVENT_EVALUATOR : %s : QUERY_OUT_OF_DIFF_APPLIES : %f"
                          (S.Event.request_id event)
                          t))
                  (fun () -> S.query_pull_request_out_of_diff_applies db event pull_request)
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
                let all_match_dirspaceflows =
                  CCList.map Terrat_change_matcher.dirspaceflow all_matches
                in
                let dirs =
                  all_match_dirspaceflows
                  |> CCList.map (fun dsf -> Terrat_change.(dsf.Dirspaceflow.dirspace.Dirspace.dir))
                  |> Dir_set.of_list
                in
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m
                          "EVENT_EVALUATOR : %s : LIST_EXISTING_DIRS : %f"
                          (S.Event.request_id event)
                          t))
                  (fun () -> S.list_existing_dirs event pull_request dirs)
                >>= fun existing_dirs ->
                let missing_dirs = Dir_set.diff dirs existing_dirs in
                Logs.info (fun m ->
                    m
                      "EVENT_EVALUATOR : %s : MISSING_DIRS : %d"
                      (S.Event.request_id event)
                      (Dir_set.cardinal missing_dirs));
                let all_match_dirspaceflows =
                  all_match_dirspaceflows
                  |> CCList.filter (fun dsf ->
                         Dir_set.mem
                           Terrat_change.(dsf.Dirspaceflow.dirspace.Dirspace.dir)
                           existing_dirs)
                in
                let tag_query_matches =
                  tag_query_matches
                  |> CCList.filter (fun tcm ->
                         let dsf = tcm.Terrat_change_matcher.dirspaceflow in
                         Dir_set.mem
                           Terrat_change.(dsf.Dirspaceflow.dirspace.Dirspace.dir)
                           existing_dirs)
                in
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m
                          "EVENT_EVALUATOR : %s : STORE_DIRSPACEFLOWS : %f"
                          (S.Event.request_id event)
                          t))
                  (fun () -> S.store_dirspaceflows db event pull_request all_match_dirspaceflows)
                >>= fun () ->
                match unified_run_type (S.Event.run_type event) with
                | `Plan run_source_type ->
                    Abbs_time_it.run
                      (fun t ->
                        Logs.info (fun m ->
                            m
                              "EVENT_EVALUATOR : %s : PROCESS_PLAN : %f"
                              (S.Event.request_id event)
                              t))
                      (fun () ->
                        process_plan
                          db
                          event
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          run_source_type)
                | `Apply run_source_type ->
                    Abbs_time_it.run
                      (fun t ->
                        Logs.info (fun m ->
                            m
                              "EVENT_EVALUATOR : %s : PROCESS_APPLY : %f"
                              (S.Event.request_id event)
                              t))
                      (fun () ->
                        process_apply
                          db
                          event
                          tag_query_matches
                          all_match_dirspaceflows
                          pull_request
                          repo_config
                          `Apply
                          run_source_type)
                | `Unsafe_apply ->
                    Abbs_time_it.run
                      (fun t ->
                        Logs.info (fun m ->
                            m
                              "EVENT_EVALUATOR : %s : PROCESS_UNSAFE_APPLY : %f"
                              (S.Event.request_id event)
                              t))
                      (fun () ->
                        process_apply
                          db
                          event
                          tag_query_matches
                          all_match_dirspaceflows
                          pull_request
                          repo_config
                          `Unsafe_apply
                          `Manual))
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
    match S.Event.run_type event with
    | Terrat_work_manifest.Run_type.Autoplan | Terrat_work_manifest.Run_type.Autoapply ->
        Logs.info (fun m ->
            m
              "EVENT_EVALUATOR : %s : %s_BRANCH_NOT_VALID_BRANCH"
              (S.Event.request_id event)
              msg_fragment);
        Abb.Future.return (Ok None)
    | Terrat_work_manifest.Run_type.Plan
    | Terrat_work_manifest.Run_type.Apply
    | Terrat_work_manifest.Run_type.Unsafe_apply ->
        Logs.info (fun m ->
            m
              "EVENT_EVALUATOR : %s : %s_BRANCH_NOT_VALID_BRANCH_EXPLICIT"
              (S.Event.request_id event)
              msg_fragment);
        Abb.Future.return (Ok (Some (Msg.Dest_branch_no_match pull_request)))

  let fetch_dest_repo_config event pull_request =
    let open Abbs_future_combinators.Infix_result_monad in
    S.fetch_repo_config event pull_request (S.Event.default_branch event)
    >>| fun repo_default_config ->
    match is_valid_destination_branch event pull_request repo_default_config with
    | Ok () -> Ok repo_default_config
    | Error _ as err -> err

  let run' storage event =
    let module Run_type = Terrat_work_manifest.Run_type in
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR: %s : FETCHING_PULL_REQUEST : %f" (S.Event.request_id event) t))
      (fun () -> S.fetch_pull_request event)
    >>= fun pull_request ->
    Abbs_future_combinators.Infix_result_app.(
      (fun repo_config repo_dest_config repo_tree -> (repo_config, repo_dest_config, repo_tree))
      <$> Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "EVENT_EVALUATOR: %s : FETCHING_REPO_CONFIG : %f" (S.Event.request_id event) t))
            (fun () -> S.fetch_repo_config event pull_request (S.Pull_request.hash pull_request))
      <*> Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m
                    "EVENT_EVALUATOR: %s : FETCHING_DEST_REPO_CONFIG : %f"
                    (S.Event.request_id event)
                    t))
            (fun () -> fetch_dest_repo_config event pull_request)
      <*> Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "EVENT_EVALUATOR : %s : FETCHING_REPO_TREE : %f" (S.Event.request_id event) t))
            (fun () -> S.fetch_tree event pull_request))
    >>= fun (repo_config, repo_dest_config, repo_tree) ->
    match repo_dest_config with
    | Ok repo_dest_config ->
        if repo_config.Terrat_repo_config.Version_1.enabled then (
          match S.Pull_request.state pull_request with
          | Terrat_pull_request.State.(Open | Merged _)
            when can_apply_checkout_strategy repo_config pull_request ->
              exec_event storage event pull_request repo_config repo_tree
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
                  Abbs_time_it.run
                    (fun t ->
                      Logs.info (fun m ->
                          m
                            "EVENT_EVALUATOR : %s : STORE_PULL_REQUEST : %f"
                            (S.Event.request_id event)
                            t))
                    (fun () -> S.store_pull_request db event pull_request))
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
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m "EVENT_EVALUATOR : %s : PUBLISH_MSG : %f" (S.Event.request_id event) t))
                  (fun () -> S.publish_msg event msg)
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
