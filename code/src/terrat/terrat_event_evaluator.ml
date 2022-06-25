module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

module Msg = struct
  type 'pull_request t =
    | Missing_plans of Terrat_change.Dirspace.t list
    | Dirspaces_owned_by_other_pull_request of 'pull_request Dirspace_map.t
    | Conflicting_apply_running of 'pull_request
    | Conflicting_apply_queued of 'pull_request
    | Repo_config_parse_failure of string
    | Repo_config_failure of string
    | Pull_request_not_appliable of 'pull_request
    | Pull_request_not_mergeable of 'pull_request
    | Apply_no_matching_dirspaces
    | Plan_no_matching_dirspaces
end

module type S = sig
  module Event : sig
    type t

    val request_id : t -> string
    val run_type : t -> Terrat_work_manifest.Run_type.t
    val tag_query : t -> Terrat_tag_set.t
  end

  module Pull_request : sig
    type t

    val base_hash : t -> string
    val hash : t -> string
    val diff : t -> Terrat_change.Diff.t list
    val state : t -> Terrat_pull_request.State.t
    val passed_all_checks : t -> bool
    val mergeable : t -> bool option
  end

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
    ( Terrat_repo_config.Version_1.t,
      [> `Repo_config_parse_err of string | `Repo_config_err of string ] )
    result
    Abb.Future.t

  val fetch_pull_request : Event.t -> (Pull_request.t, [> `Error ]) result Abb.Future.t

  val query_existing_apply_in_repo :
    Pgsql_io.t ->
    Event.t ->
    (Pull_request.t Terrat_work_manifest.Existing_lite.t option, [> `Error ]) result Abb.Future.t

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

module Make (S : S) = struct
  let compute_matches repo_config tag_query out_of_change_applies diff =
    let all_matching_dirspaces =
      Terrat_change_matcher.map_dirspace repo_config out_of_change_applies
    in
    let all_matching_diff = Terrat_change_matcher.match_diff repo_config diff in
    let all_matches = Terrat_change_matcher.merge_dedup all_matching_dirspaces all_matching_diff in
    let all_match_dirspaceflows = CCList.map Terrat_change_matcher.dirspaceflow all_matches in
    let tag_query_matches =
      Terrat_change_matcher.map_dirspace
        ~tag_query
        repo_config
        (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows)
    in
    (tag_query_matches, all_match_dirspaceflows)

  let can_apply_checkout_strategy repo_config pull_request =
    match
      ( S.Pull_request.mergeable pull_request,
        repo_config.Terrat_repo_config.Version_1.checkout_strategy )
    with
    | Some mergeable, "merge" -> mergeable
    | (Some _ | _), _ -> true

  let create_and_store_work_manifest db event pull_request matches =
    let open Abbs_future_combinators.Infix_result_monad in
    let work_manifest =
      Terrat_work_manifest.
        {
          base_hash = S.Pull_request.base_hash pull_request;
          changes = CCList.map Terrat_change_matcher.dirspaceflow matches;
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
    Logs.info (fun m -> m "EVENT_EVALUATOR : %s : CREATE_WORK_MANIFEST" (S.Event.request_id event));
    S.store_new_work_manifest db event work_manifest >>= fun _ -> Abb.Future.return (Ok None)

  let process_plan db event tag_query_matches pull_request run_type =
    let matches =
      match run_type with
      | `Auto ->
          CCList.filter
            (fun {
                   Terrat_change_matcher.when_modified =
                     Terrat_repo_config.When_modified.{ autoplan; _ };
                   _;
                 } -> autoplan)
            tag_query_matches
      | `Manual -> tag_query_matches
    in
    match (S.Event.run_type event, matches) with
    | Terrat_work_manifest.Run_type.Autoplan, [] ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : NOOP : AUTOPLAN_NO_MATCHES" (S.Event.request_id event));
        Abb.Future.return (Ok None)
    | _, [] ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : NOOP : PLAN_NO_MATCHING_DIRSPACES" (S.Event.request_id event));
        Abb.Future.return (Ok (Some Msg.Plan_no_matching_dirspaces))
    | _, _ -> create_and_store_work_manifest db event pull_request matches

  let process_apply db event tag_query_matches all_match_dirspaceflows pull_request run_type =
    let open Abbs_future_combinators.Infix_result_monad in
    Logs.info (fun m ->
        m "EVENT_EVALUATOR : %s : MISSING_APPLIED_DIRSPACES" (S.Event.request_id event));
    S.query_unapplied_dirspaces db event pull_request
    >>= fun missing_dirspaces ->
    (* Filter only those missing *)
    let tag_query_matches =
      CCList.filter
        (fun Terrat_change_matcher.{ dirspaceflow = Terrat_change.Dirspaceflow.{ dirspace; _ }; _ } ->
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
      match run_type with
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
            m "EVENT_EVALUATOR : %s : NOOP : APPLY_NO_MATCHING_DIRSPACES" (S.Event.request_id event));
        Abb.Future.return (Ok (Some Msg.Apply_no_matching_dirspaces))
    | _, _ -> (
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : QUERY_DIRSPACES_OWNED_BY_OTHER_PRS" (S.Event.request_id event));
        S.query_dirspaces_owned_by_other_pull_requests
          db
          event
          pull_request
          (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows)
        >>= function
        | dirspaces when Dirspace_map.is_empty dirspaces -> (
            (* None of the dirspaces are owned by another PR, we can proceed *)
            Logs.info (fun m ->
                m
                  "EVENT_EVALUATOR : %s : QUERY_DIRSPACES_WITHOUT_VALID_PLANS"
                  (S.Event.request_id event));
            S.query_dirspaces_without_valid_plans
              db
              event
              pull_request
              (CCList.map
                 CCFun.(
                   Terrat_change_matcher.dirspaceflow %> Terrat_change.Dirspaceflow.to_dirspace)
                 matches)
            >>= function
            | [] ->
                (* All are ready to be applied *)
                create_and_store_work_manifest db event pull_request matches
            | dirspaces ->
                (* Some are missing plans *)
                Abb.Future.return (Ok (Some (Msg.Missing_plans dirspaces))))
        | dirspaces ->
            (* Some are owned by another PR, abort *)
            Abb.Future.return (Ok (Some (Msg.Dirspaces_owned_by_other_pull_request dirspaces))))

  let exec_event storage event pull_request repo_config =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.tx db ~f:(fun () ->
            Logs.info (fun m ->
                m "EVENT_EVALUATOR : %s : STORE_PULL_REQUEST" (S.Event.request_id event));
            S.store_pull_request db event pull_request
            >>= fun () ->
            Logs.info (fun m ->
                m "EVENT_EVALUATOR : %s : QUERY_RUNNING_APPLY" (S.Event.request_id event));
            S.query_existing_apply_in_repo db event
            >>= function
            | Some wm when Terrat_work_manifest.(wm.state = State.Running) ->
                Abb.Future.return
                  (Ok (Some (Msg.Conflicting_apply_running wm.Terrat_work_manifest.pull_request)))
            | Some wm ->
                Abb.Future.return
                  (Ok (Some (Msg.Conflicting_apply_queued wm.Terrat_work_manifest.pull_request)))
            | None -> (
                (* Collect any changes that have been applied outside of the current
                   state of the PR.  For example, we made a change to dir1 and dir2,
                   applied dir1, then we updated our PR to revert dir1, we would
                   want to be able to plan and apply dir1 again even though it
                   doesn't look like dir1 changes. *)
                Logs.info (fun m ->
                    m "EVENT_EVALUATOR : %s : QUERY_OUT_OF_DIFF_APPLIES" (S.Event.request_id event));
                S.query_pull_request_out_of_diff_applies db event pull_request
                >>= fun out_of_change_applies ->
                let tag_query_matches, all_match_dirspaceflows =
                  compute_matches
                    repo_config
                    (S.Event.tag_query event)
                    out_of_change_applies
                    (S.Pull_request.diff pull_request)
                in
                Logs.info (fun m ->
                    m "EVENT_EVALUATOR : %s : STORE_DIRSPACEFLOWS" (S.Event.request_id event));
                S.store_dirspaceflows db event pull_request all_match_dirspaceflows
                >>= fun () ->
                match unified_run_type (S.Event.run_type event) with
                | `Plan run_type -> process_plan db event tag_query_matches pull_request run_type
                | `Apply run_type when S.Pull_request.passed_all_checks pull_request ->
                    process_apply
                      db
                      event
                      tag_query_matches
                      all_match_dirspaceflows
                      pull_request
                      run_type
                | `Apply _ ->
                    Logs.info (fun m ->
                        m "EVENT_EVALUATOR : %s : PR_NOT_APPLIABLE" (S.Event.request_id event));
                    Abb.Future.return (Ok (Some (Msg.Pull_request_not_appliable pull_request))))))

  let run' storage event =
    let module Run_type = Terrat_work_manifest.Run_type in
    let open Abbs_future_combinators.Infix_result_monad in
    Logs.info (fun m -> m "EVENT_EVALUATOR : %s : FETCHING_PULL_REQUEST" (S.Event.request_id event));
    S.fetch_pull_request event
    >>= fun pull_request ->
    Logs.info (fun m -> m "EVENT_EVALUATOR : %s : FETCHING_REPO_CONFIG" (S.Event.request_id event));
    S.fetch_repo_config event pull_request
    >>= fun repo_config ->
    if repo_config.Terrat_repo_config.Version_1.enabled then (
      match S.Pull_request.state pull_request with
      | Terrat_pull_request.State.(Open | Merged _)
        when can_apply_checkout_strategy repo_config pull_request ->
          exec_event storage event pull_request repo_config
      | Terrat_pull_request.State.(Open | Merged _) ->
          (* Cannot apply checkout strategy *)
          Logs.info (fun m ->
              m "EVENT_EVALUATOR : %s : CANNOT_APPLY_CHECKOUT_STRATEGY" (S.Event.request_id event));
          Abb.Future.return (Ok (Some (Msg.Pull_request_not_mergeable pull_request)))
      | Terrat_pull_request.State.Closed ->
          Logs.info (fun m ->
              m "EVENT_EVALUATOR : %s : NOOP : PR_CLOSED" (S.Event.request_id event));
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Logs.info (fun m ->
                  m "EVENT_EVALUATOR : %s : STORE_PULL_REQUEST" (S.Event.request_id event));
              S.store_pull_request db event pull_request)
          >>= fun () -> Abb.Future.return (Ok None))
    else (
      Logs.info (fun m ->
          m "EVENT_EVALUATOR : %s : NOOP : REPO_CONFIG_DISABLED" (S.Event.request_id event));
      Abb.Future.return (Ok None))

  let run storage event =
    let open Abb.Future.Infix_monad in
    run' storage event
    >>= function
    | Ok (Some msg) -> S.publish_msg event msg
    | Ok None -> Abb.Future.return ()
    | Error (`Repo_config_parse_err err) ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : REPO_CONFIG_PARSE_ERROR : %s" (S.Event.request_id event) err);
        S.publish_msg event (Msg.Repo_config_parse_failure err)
    | Error (`Repo_config_err err) ->
        Logs.info (fun m ->
            m "EVENT_EVALUATOR : %s : REPO_CONFIG_ERROR : %s" (S.Event.request_id event) err);
        S.publish_msg event (Msg.Repo_config_failure err)
    | Error `Error ->
        Logs.err (fun m -> m "EVENT_EVALUATOR : %s : ERROR : ERROR" (S.Event.request_id event));
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
            m "EVENT_EVALUATOR : %s : ERROR : %s" (S.Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return ()
end
