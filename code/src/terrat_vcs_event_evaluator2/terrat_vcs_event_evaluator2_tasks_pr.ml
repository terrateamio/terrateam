module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks_pr." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Repo_tree_wm = Terrat_vcs_event_evaluator2_wm_sm_repo_tree.Make (S) (Keys)
  module Build_config_wm = Terrat_vcs_event_evaluator2_wm_sm_build_config.Make (S) (Keys)
  module Indexer_wm = Terrat_vcs_event_evaluator2_wm_sm_indexer.Make (S) (Keys)
  module Tf_op_wm = Terrat_vcs_event_evaluator2_wm_sm_tf_op.Make (S) (Keys)
  module Access_control = Terrat_vcs_event_evaluator2_access_control.Make (S) (Keys)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks_base = Terrat_vcs_event_evaluator2_tasks_base.Make (S) (Keys)

  module H = struct
    let match_tag_queries ~accessor ~changes queries =
      CCList.map
        (fun change ->
          ( change,
            CCList.find_idx
              (fun q -> Terrat_change_match3.match_tag_query ~tag_query:(accessor q) change)
              queries ))
        changes

    let replace_stack_vars vars s =
      Str_template.apply (CCFun.flip Terrat_data.String_map.find_opt vars) s

    let apply_stack_vars_to_workflow stack workflow =
      let module R = Terrat_base_repo_config_v1 in
      let module E = R.Workflows.Entry in
      let module S = R.Stacks.Stack in
      let {
        E.apply = _;
        engine = _;
        environment;
        integrations = _;
        lock_policy = _;
        plan = _;
        runs_on = _;
        tag_query = _;
      } =
        workflow
      in
      let open CCResult.Infix in
      CCResult.opt_map (replace_stack_vars stack.S.variables) environment
      >>= fun environment -> Ok { workflow with E.environment }

    let dirspaceflows_of_changes_with_branch_target repo_config changes =
      let module R = Terrat_base_repo_config_v1 in
      let module S = R.Stacks in
      let workflows = R.workflows repo_config in
      CCResult.map_l
        (fun ( {
                 Terrat_change_match3.Dirspace_config.dirspace;
                 lock_branch_target;
                 stack_config = { S.Stack.variables; _ } as stack_config;
                 _;
               },
               workflow )
           ->
          let open CCResult.Infix in
          let module Dsf = Terrat_change.Dirspaceflow in
          CCResult.opt_map
            (fun (idx, workflow) ->
              let open CCResult.Infix in
              apply_stack_vars_to_workflow stack_config workflow
              >>= fun workflow -> Ok { Dsf.Workflow.idx; workflow })
            workflow
          >>= fun workflow ->
          Ok { Dsf.dirspace; workflow = (lock_branch_target, workflow); variables = Some variables })
        (match_tag_queries
           ~accessor:(fun { R.Workflows.Entry.tag_query; _ } -> tag_query)
           ~changes
           workflows)

    let strip_lock_branch_target dsfs =
      let module Dsf = Terrat_change.Dirspaceflow in
      CCList.map (fun ({ Dsf.workflow = _, workflow; _ } as dsf) -> { dsf with Dsf.workflow }) dsfs

    let dirspaceflows_of_changes repo_config changes =
      let open CCResult.Infix in
      dirspaceflows_of_changes_with_branch_target repo_config changes
      >>= fun dirspaceflows -> Ok (strip_lock_branch_target dirspaceflows)
  end

  module Tasks = struct
    let run = Tasks_base.run

    (* Wrapper so that when we call [publish_comment] the error type lines up *)
    let publish_comment' f msg =
      let open Abb.Future.Infix_monad in
      f msg
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error `Error -> Abb.Future.return (Error `Error)

    let create_commit_checks' f branch_ref checks =
      let open Abb.Future.Infix_monad in
      f branch_ref checks
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error `Error -> Abb.Future.return (Error `Error)

    let publish_comment =
      run ~name:"publish_comment" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.user
          >>= fun user ->
          Abb.Future.return
            (Ok
               (fun msg ->
                 S.Comment.publish_comment
                   ~request_id:(Builder.log_id s)
                   client
                   (CCOption.map_or ~default:"" S.Api.User.to_string user)
                   pull_request
                   msg)))

    let create_commit_checks =
      run ~name:"create_commit_checks" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.repo
          >>= fun repo ->
          Abb.Future.return
            (Ok
               (fun branch_ref checks ->
                 S.Api.create_commit_checks
                   ~request_id:(Builder.log_id s)
                   client
                   repo
                   branch_ref
                   checks)))

    let branch_name =
      run ~name:"branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_name pull_request)))

    let branch_ref =
      run ~name:"branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_ref pull_request)))

    let dest_branch_name =
      run ~name:"dest_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.base_branch_name pull_request)))

    let dest_branch_ref =
      run ~name:"dest_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request -> Abb.Future.return (Ok (S.Api.Pull_request.base_ref pull_request)))

    let working_branch_ref =
      run ~name:"working_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Terrat_pull_request.State.Open _ | Terrat_pull_request.State.Closed ->
              Abb.Future.return (Ok (S.Api.Pull_request.branch_ref pull_request))
          | Terrat_pull_request.State.Merged _ -> fetch Keys.default_branch_sha)

    let working_branch_name =
      run ~name:"working_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Terrat_pull_request.State.Open _ | Terrat_pull_request.State.Closed ->
              Abb.Future.return (Ok (S.Api.Pull_request.branch_name pull_request))
          | Terrat_pull_request.State.Merged _ ->
              Abb.Future.return (Ok (S.Api.Pull_request.base_branch_name pull_request)))

    let out_of_change_applies =
      run ~name:"out_of_change_applies" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_pull_request_out_of_change_applies
                ~request_id:(Builder.log_id s)
                db
                pull_request))

    let changes = run ~name:"changes" (fun _s { Bs.Fetcher.fetch } -> fetch Keys.pull_request_diff)

    let missing_autoplan_matches =
      run ~name:"missing_autoplan_matches" (fun s { Bs.Fetcher.fetch } ->
          let module Dc = Terrat_change_match3.Dirspace_config in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return
            (Ok
               (fun matches ->
                 Builder.run_db s ~f:(fun db ->
                     S.Db.query_dirspaces_without_valid_plans
                       ~request_id:(Builder.log_id s)
                       db
                       pull_request
                       (CCList.map (fun { Dc.dirspace; _ } -> dirspace) matches))
                 >>= fun dirspaces ->
                 let dirspaces = Terrat_data.Dirspace_set.of_list dirspaces in
                 Abb.Future.return
                   (Ok
                      (CCList.filter
                         (fun { Dc.dirspace; _ } -> Terrat_data.Dirspace_set.mem dirspace dirspaces)
                         matches)))))

    let is_draft_pr =
      run ~name:"is_draft_pr" (fun _s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.is_draft_pr pull_request)))

    let publish_index_complete =
      run ~name:"publish_index_complete" (fun s { Bs.Fetcher.fetch } ->
          let module I = Terrat_vcs_provider2.Index in
          let open Irm in
          Fc.Result.all2 (fetch Keys.repo_index_branch) (fetch Keys.repo_index_dest_branch)
          >>= fun (_, _) ->
          fetch Keys.account
          >>= fun account ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Logs.info (fun m -> m "%s : FETCHING_INDEX" (Builder.log_id s));
          Builder.run_db s ~f:(fun db ->
              S.Db.query_index ~request_id:(Builder.log_id s) db account branch_ref)
          >>= function
          | Some { I.success; failures; _ } -> (
              (* TODO: Construct include base branch index information as well, if it was generated *)
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              let open Abb.Future.Infix_monad in
              publish_comment'
                publish_comment
                (Msg.Index_complete
                   ( success,
                     CCList.map
                       (fun { I.Failure.file; line_num; error } -> (file, line_num, error))
                       failures ))
              >>= function
              | Ok () -> Abb.Future.return (Ok ())
              | Error `Error -> Abb.Future.return (Error `Error))
          | None ->
              Logs.info (fun m -> m "%s : INDEX_NOT_FOUND" (Builder.log_id s));
              Abb.Future.return (Ok ()))

    let publish_unlock =
      run ~name:"publish_unlock" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let eval_access_control () =
            fetch Keys.repo_config
            >>= fun repo_config ->
            fetch Keys.access_control
            >>= fun access_control ->
            let module Ac = Terrat_base_repo_config_v1.Access_control in
            let ac_conf = Terrat_base_repo_config_v1.access_control repo_config in
            if ac_conf.Ac.enabled then
              let match_list = ac_conf.Ac.unlock in
              Access_control.eval_match_list access_control match_list
              >>= function
              | true -> Abb.Future.return (Ok None)
              | false -> Abb.Future.return (Ok (Some match_list))
            else Abb.Future.return (Ok None)
          in
          let parse_unlock_ids pull_request_id = function
            | [] -> Ok [ S.Unlock_id.of_pull_request pull_request_id ]
            | unlock_ids ->
                CCResult.map_l
                  (function
                    | "drift" -> Ok (S.Unlock_id.drift ())
                    | s -> (
                        match S.Api.Pull_request.Id.of_string s with
                        | Some id -> Ok (S.Unlock_id.of_pull_request id)
                        | None -> Error (`Invalid_unlock_id s)))
                  unlock_ids
          in
          let run client pull_request unlock_ids =
            let open Irm in
            fetch Keys.repo
            >>= fun repo ->
            fetch Keys.access_control
            >>= fun access_control ->
            fetch Keys.publish_comment
            >>= fun publish_comment ->
            eval_access_control ()
            >>= function
            | None ->
                let open Irm in
                Builder.run_db s ~f:(fun db ->
                    Abbs_future_combinators.List_result.iter
                      ~f:(S.Db.unlock ~request_id:(Builder.log_id s) db repo)
                      unlock_ids)
                >>= fun () -> publish_comment' publish_comment Msg.Unlock_success
            | Some match_list ->
                publish_comment'
                  publish_comment
                  (Msg.Access_control_denied
                     ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                       `Unlock match_list ))
          in
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.job
          >>= fun job ->
          match job.Tjc.Job.type_ with
          | Tjc.Job.Type_.Unlock unlock_ids -> (
              fetch Keys.pull_request
              >>= fun pull_request ->
              let open Abb.Future.Infix_monad in
              Abb.Future.return @@ parse_unlock_ids (S.Api.Pull_request.id pull_request) unlock_ids
              >>= function
              | Ok unlock_ids -> run client pull_request unlock_ids
              | Error (`Invalid_unlock_id id) ->
                  let open Irm in
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  publish_comment' publish_comment (Msg.Invalid_unlock_id id))
          | _ -> assert false)

    let publish_repo_config =
      run ~name:"publish_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.repo_config_with_provenance) (fetch Keys.store_stacks)
          >>= fun (repo_config_with_provenance, ()) ->
          fetch Keys.publish_comment
          >>= fun publish_comment ->
          publish_comment' publish_comment (Msg.Repo_config repo_config_with_provenance))

    let comment_id =
      run ~name:"comment_id" (fun s { Bs.Fetcher.fetch } ->
          (* This is a default value in case no comment id is set in the store
             by the runner. *)
          Abb.Future.return (Ok None))

    let react_to_comment =
      run ~name:"react_to_comment" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.comment_id
          >>= function
          | Some comment_id ->
              Fc.Result.all2 (fetch Keys.pull_request) (fetch Keys.client)
              >>= fun (pull_request, client) ->
              S.Api.react_to_comment ~request_id:(Builder.log_id s) client pull_request comment_id
          | None -> Abb.Future.return (Ok ()))

    let pull_request =
      run ~name:"pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all4
            (fetch Keys.account)
            (fetch Keys.repo)
            (fetch Keys.client)
            (fetch Keys.pull_request_id)
          >>= fun (account, repo, client, pull_request_id) ->
          S.Api.fetch_pull_request
            ~request_id:(Builder.log_id s)
            account
            client
            repo
            pull_request_id)

    let pull_request_diff =
      run ~name:"pull_request_diff" (fun s { Bs.Fetcher.fetch } ->
          let module V1 = Terrat_base_repo_config_v1 in
          let module I = Terrat_api_components.Work_manifest_build_tree_result.Files.Items in
          let open Irm in
          fetch Keys.repo_config
          >>= fun repo_config ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          let diff = S.Api.Pull_request.diff pull_request in
          let tree_builder = V1.tree_builder repo_config in
          if tree_builder.V1.Tree_builder.enabled then
            let changed_files =
              Terrat_data.String_set.of_list
              @@ CCList.flat_map
                   (function
                     | Terrat_change.Diff.Add { filename }
                     | Terrat_change.Diff.Change { filename }
                     | Terrat_change.Diff.Remove { filename } -> [ filename ]
                     | Terrat_change.Diff.Move { filename; previous_filename } ->
                         [ filename; previous_filename ])
                   diff
            in
            fetch Keys.repo_tree_branch
            >>= fun _ ->
            fetch Keys.account
            >>= fun account ->
            fetch Keys.branch_ref
            >>= fun branch_ref ->
            fetch Keys.dest_branch_ref
            >>= fun dest_branch_ref ->
            Fc.Result.all2 (fetch Keys.repo_tree_branch) (fetch Keys.repo_tree_dest_branch)
            >>= fun (_, _) ->
            Builder.run_db s ~f:(fun db ->
                S.Db.query_repo_tree
                  ~request_id:(Builder.log_id s)
                  ~base_ref:dest_branch_ref
                  db
                  account
                  branch_ref)
            >>= function
            | Some repo_tree ->
                Abb.Future.return
                  (Ok
                     (CCList.filter_map
                        (function
                          | { I.path = filename; changed = Some true; _ } ->
                              Some (Terrat_change.Diff.Change { filename })
                          | { I.path = filename; changed = None; _ }
                            when Terrat_data.String_set.mem filename changed_files ->
                              Some (Terrat_change.Diff.Change { filename })
                          | _ -> None)
                        repo_tree))
            | None -> assert false
          else Abb.Future.return (Ok diff))

    let store_pull_request =
      run ~name:"store_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Logs.info (fun m ->
              m
                "%s : STORE_PULL_REQUEST : pull_number=%s"
                (Builder.log_id s)
                (S.Api.Pull_request.Id.to_string @@ S.Api.Pull_request.id pull_request));
          Builder.run_db s ~f:(fun db ->
              S.Db.store_pull_request ~request_id:(Builder.log_id s) db pull_request))

    let check_pull_request_state =
      run ~name:"check_pull_request_state" (fun s { Bs.Fetcher.fetch } ->
          let module Pr = Terrat_pull_request in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Pr.State.Closed ->
              Logs.info (fun m -> m "%s : NOOP : PR_CLOSED" (Builder.log_id s));
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              fetch Keys.branch_ref
              >>= fun branch_ref ->
              S.Api.fetch_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref
              >>= fun commit_checks ->
              let module Ch = Terrat_commit_check in
              let unfinished_checks =
                CCList.filter_map
                  (function
                    | { Ch.status = Ch.Status.(Completed | Failed | Canceled); _ } -> None
                    | { Ch.status = Ch.Status.(Queued | Running); _ } as c ->
                        Some { c with Ch.status = Ch.Status.Canceled })
                  commit_checks
              in
              fetch Keys.create_commit_checks
              >>= fun create_commit_checks ->
              create_commit_checks' create_commit_checks branch_ref unfinished_checks
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Pr.State.(Open _ | Merged _) -> Abb.Future.return (Ok ()))

    let check_conflicting_plan_work_manifests =
      run ~name:"check_conflicting_plan_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.access_control_eval_plan
          >>= fun access_control_eval ->
          Abb.Future.return
            (access_control_eval
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { R.pass = passed_dirspaces; _ } ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              passed_dirspaces
          in
          (* TODO: Do not depend on pull request *)
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_conflicting_work_manifests_in_repo
                ~request_id:(Builder.log_id s)
                db
                pull_request
                dirspaces
                `Plan)
          >>= function
          | None -> Abb.Future.return (Ok ())
          | Some (P2.Conflicting_work_manifests.Conflicting wms) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment' publish_comment (Msg.Conflicting_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Some (P2.Conflicting_work_manifests.Maybe_stale wms) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment' publish_comment (Msg.Maybe_stale_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_merge_conflict =
      run ~name:"check_merge_conflict" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Terrat_pull_request.State.(Open Open_status.Merge_conflict) -> (
              fetch Keys.all_matches
              >>= function
              | [] -> Abb.Future.return (Error `Noop)
              | _ :: _ ->
                  Logs.info (fun m -> m "%s : MERGE_CONFLICT" (Builder.log_id s));
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  publish_comment' publish_comment Msg.Pull_request_not_mergeable
                  >>= fun () -> Abb.Future.return (Error `Noop))
          | Terrat_pull_request.State.Open _
          | Terrat_pull_request.State.Closed
          | Terrat_pull_request.State.Merged _ -> Abb.Future.return (Ok ()))

    let pull_request_reviews =
      run ~name:"pull_request_reviews" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          S.Api.fetch_pull_request_reviews
            ~request_id:(Builder.log_id s)
            repo
            (S.Api.Pull_request.id pull_request)
            client)

    let access_control_eval_plan =
      run ~name:"access_control_eval_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_tf_operation access_control working_set_matches `Plan
          >>= fun ret -> Abb.Future.return (Ok ret))

    let access_control_eval_apply =
      run ~name:"access_control_eval_apply" (fun s { Bs.Fetcher.fetch } ->
          let module Rr = Terrat_pull_request_review in
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request_reviews
          >>= fun reviews ->
          let reviews =
            CCList.filter_map
              (function
                | { Rr.user; status = Rr.Status.Approved; _ } -> user
                | _ -> None)
              reviews
          in
          fetch Keys.job
          >>= fun job ->
          let op =
            match job with
            | {
             Tjc.Job.type_ =
               Tjc.Job.Type_.(Autoapply | Apply { tag_query = _; kind = _; force = false });
             _;
            } -> `Apply reviews
            | { Tjc.Job.type_ = Tjc.Job.Type_.Apply { tag_query = _; kind = _; force = true }; _ }
              -> `Apply_force
            | _ -> assert false
          in
          let open Abb.Future.Infix_monad in
          Access_control.eval_tf_operation access_control working_set_matches op
          >>= fun ret -> Abb.Future.return (Ok ret))

    let check_access_control_plan =
      run ~name:"check_access_control_plan" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.access_control_eval_plan
          >>= function
          | Ok { R.pass = []; deny = _ :: _ as deny }
            when not (Access_control.plan_require_all_dirspace_access access_control) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `All_dirspaces deny ))
          | Ok { R.pass; deny }
            when CCList.is_empty deny
                 || not (Access_control.plan_require_all_dirspace_access access_control) ->
              Abb.Future.return (Ok ())
          | Ok { R.deny; _ } ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Dirspaces deny ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Error `Error ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Lookup_err ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_apply_requirements =
      run ~name:"check_apply_requirements" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all5
            (fetch Keys.client)
            (fetch Keys.repo_config)
            (fetch Keys.pull_request)
            (fetch Keys.working_set_matches)
            (fetch Keys.user)
          >>= fun (client, repo_config, pull_request, working_set_matches, user) ->
          match user with
          | Some user -> (
              S.Apply_requirements.eval
                ~request_id:(Builder.log_id s)
                (Builder.State.config s)
                user
                client
                repo_config
                pull_request
                working_set_matches
              >>= fun apply_requirements ->
              let passed_apply_requirements =
                S.Apply_requirements.Result.passed apply_requirements
              in
              fetch Keys.job
              >>= function
              | {
                  Tjc.Job.type_ = Tjc.Job.Type_.Apply { force = false; tag_query = _; kind = _ };
                  _;
                }
                when not passed_apply_requirements ->
                  Logs.info (fun m -> m "%s : PR_NOT_APPLIABLE" (Builder.log_id s));
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  publish_comment'
                    publish_comment
                    (Msg.Pull_request_not_appliable
                       ( S.Api.Pull_request.set_checks ()
                         @@ S.Api.Pull_request.set_diff () pull_request,
                         apply_requirements ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | _ -> Abb.Future.return (Ok apply_requirements))
          | None -> assert false)

    let check_access_control_apply =
      run ~name:"check_access_control_apply" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          fetch Keys.check_apply_requirements
          >>= fun apply_requirements ->
          let op =
            match job with
            | {
             Tjc.Job.type_ =
               Tjc.Job.Type_.(Autoapply | Apply { tag_query = _; kind = _; force = false });
             _;
            } ->
                `Apply
                  (CCList.filter_map
                     (fun { Terrat_pull_request_review.user; _ } -> user)
                     (S.Apply_requirements.Result.approved_reviews apply_requirements))
            | { Tjc.Job.type_ = Tjc.Job.Type_.Apply { tag_query = _; kind = _; force = true }; _ }
              -> `Apply_force
            | job ->
                let module Pp = struct
                  type t =
                    ( S.Api.Pull_request.Id.t,
                      S.Api.Ref.t,
                      (S.Api.User.t[@opaque]) option )
                    Terrat_job_context.Job.t
                  [@@deriving show]
                end in
                Logs.err (fun m -> m "%s : job= %a" (Builder.log_id s) Pp.pp job);
                assert false
          in
          Fc.Result.all6
            (fetch Keys.access_control)
            (fetch Keys.matches)
            (fetch Keys.client)
            (fetch Keys.pull_request)
            (fetch Keys.access_control_eval_apply)
            (fetch Keys.user)
          >>= fun (access_control, matches, client, pull_request, access_control_result, user) ->
          Abb.Future.return
            (access_control_result
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun access_control_result ->
          match access_control_result with
          | { Terrat_access_control2.R.pass = []; deny = _ :: _ as deny }
            when not (Access_control.apply_require_all_dirspace_access access_control) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `All_dirspaces deny ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | { Terrat_access_control2.R.pass; deny }
            when CCList.is_empty deny
                 || not (Access_control.apply_require_all_dirspace_access access_control) ->
              (* This is the success path *)
              Abb.Future.return (Ok ())
          | { Terrat_access_control2.R.deny; _ } ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Dirspaces deny ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_conflicting_apply_work_manifests =
      run ~name:"check_conflicting_apply_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.access_control_eval_apply
          >>= fun access_control_eval ->
          Abb.Future.return
            (access_control_eval
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { R.pass = passed_dirspaces; _ } ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              passed_dirspaces
          in
          fetch Keys.context
          >>= fun context ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_conflicting_work_manifests_in_repo_for_context
                ~request_id:(Builder.log_id s)
                db
                context
                dirspaces
                `Apply)
          >>= function
          | None -> Abb.Future.return (Ok ())
          | Some (P2.Conflicting_work_manifests.Conflicting wms) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment' publish_comment (Msg.Conflicting_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Some (P2.Conflicting_work_manifests.Maybe_stale wms) ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment' publish_comment (Msg.Maybe_stale_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_dirspaces_missing_plans =
      run ~name:"check_dirspaces_missing_plans" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.access_control_eval_apply
          >>= fun access_control_result ->
          Abb.Future.return
            (access_control_result
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { Terrat_access_control2.R.pass = working_set_matches; _ } ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_dirspaces_without_valid_plans
                ~request_id:(Builder.log_id s)
                db
                pull_request
                (CCList.map
                   (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
                   working_set_matches))
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | dirspaces -> (
              fetch Keys.job
              >>= function
              | { Tjc.Job.type_ = Tjc.Job.Type_.Autoapply; _ } ->
                  (* If it's an autoapply, don't publish *)
                  Abb.Future.return (Error `Noop)
              | _ ->
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  publish_comment' publish_comment (Msg.Missing_plans dirspaces)
                  >>= fun () -> Abb.Future.return (Error `Noop)))

    let check_dirspaces_to_plan =
      run ~name:"check_dirspaces_to_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= function
          | { Tjc.Job.type_ = Tjc.Job.Type_.Plan _; _ } -> (
              fetch Keys.all_matches
              >>= function
              | [] ->
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  Fc.Result.all2
                    (fetch Keys.maybe_create_completed_apply_check)
                    (publish_comment' publish_comment Msg.Plan_no_matching_dirspaces)
                  >>= fun ((), ()) -> Abb.Future.return (Error `Noop)
              | _ :: _ ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.working_branch_ref
                  >>= fun working_branch_ref ->
                  let checks =
                    [
                      S.Commit_check.make_str
                        ~config:(Builder.State.config s)
                        ~description:"Waiting"
                        ~status:Terrat_commit_check.Status.Queued
                        ~repo
                        ~account
                        "terrateam apply";
                    ]
                  in
                  fetch Keys.create_commit_checks
                  >>= fun create_commit_checks ->
                  create_commit_checks' create_commit_checks working_branch_ref checks)
          | _ -> Abb.Future.return (Ok ()))

    let check_dirspaces_to_apply =
      run ~name:"check_dirspaces_to_apply" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= function
          | { Tjc.Job.type_ = Tjc.Job.Type_.Autoapply; _ } -> (
              fetch Keys.working_set_matches
              >>= function
              | [] -> Abb.Future.return (Error `Noop)
              | _ :: _ -> Abb.Future.return (Ok ()))
          | { Tjc.Job.type_ = Tjc.Job.Type_.Apply _; _ } -> (
              fetch Keys.working_set_matches
              >>= function
              | [] ->
                  fetch Keys.publish_comment
                  >>= fun publish_comment ->
                  publish_comment' publish_comment Msg.Apply_no_matching_dirspaces
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | _ :: _ -> Abb.Future.return (Ok ()))
          | _ -> Abb.Future.return (Ok ()))

    let check_gates =
      run ~name:"check_gates" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.client)
            (fetch Keys.pull_request)
            (fetch Keys.working_set_matches)
          >>= fun (client, pull_request, working_set_matches) ->
          let module Dc = Terrat_change_match3.Dirspace_config in
          let dirspaces = CCList.map (fun { Dc.dirspace; _ } -> dirspace) working_set_matches in
          Builder.run_db s ~f:(fun db ->
              S.Gate.eval ~request_id:(Builder.log_id s) client dirspaces pull_request db)
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | denied ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment' publish_comment (Msg.Gate_check_failure denied)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let store_gate_approval =
      run ~name:"store_gate_approval" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.user) (fetch Keys.pull_request)
          >>= fun (user, pull_request) ->
          match user with
          | Some user -> (
              fetch Keys.job
              >>= function
              | { Tjc.Job.type_ = Tjc.Job.Type_.Gate_approval { tokens }; _ } -> (
                  let open Abb.Future.Infix_monad in
                  Builder.run_db s ~f:(fun db ->
                      Fc.List_result.iter
                        ~f:(fun token ->
                          S.Gate.add_approval
                            ~request_id:(Builder.log_id s)
                            ~token
                            ~approver:(S.Api.User.to_string user)
                            pull_request
                            db)
                        tokens)
                  >>= function
                  | Ok _ as r -> Abb.Future.return r
                  | Error #Terrat_vcs_provider2.gate_add_approval_err -> raise (Failure "nyi")
                  | Error `Closed -> raise (Failure "nyi"))
              | _ -> assert false)
          | None -> assert false)

    let check_dirspaces_owned_by_other_pull_requests =
      run ~name:"check_dirspaces_owned_by_other_pull_requests" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3 (fetch Keys.repo_config) (fetch Keys.pull_request) (fetch Keys.all_matches)
          >>= fun (repo_config, pull_request, all_matches) ->
          Abb.Future.return (H.dirspaceflows_of_changes repo_config (CCList.flatten all_matches))
          >>= fun all_match_dirspaceflows ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_dirspaces_owned_by_other_pull_requests
                ~request_id:(Builder.log_id s)
                db
                pull_request
                (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows))
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | owned_dirspaces ->
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Dirspaces_owned_by_other_pull_request owned_dirspaces)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_access_control_repo_config =
      run ~name:"check_access_control_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.changes)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_repo_config access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some match_list) ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Terrateam_config_update match_list ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Error `Error ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Lookup_err ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_access_control_files =
      run ~name:"check_access_control_files" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.changes)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_files access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some (fname, match_list)) ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Files (fname, match_list) ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Error `Error ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Lookup_err ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_access_control_ci_change =
      run ~name:"check_access_control_ci_change" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.changes)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_ci_change access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some match_list) ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Ci_config_update match_list ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Error `Error ->
              let open Irm in
              fetch Keys.publish_comment
              >>= fun publish_comment ->
              publish_comment'
                publish_comment
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Lookup_err ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let store_stacks =
      run ~name:"store_stacks" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.synthesized_config
          >>= fun config ->
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Stacks.store
                ~request_id:(Builder.log_id s)
                ~installation_id:(S.Api.Account.id account)
                ~repo_id:(S.Api.Repo.id repo)
                ~pull_request_id:(S.Api.Pull_request.id pull_request)
                config
                db))

    let can_run_plan =
      run ~name:"can_run_plan" (fun s { Bs.Fetcher.fetch } ->
          let maybe_publish_msg msg =
            let open Irm in
            fetch Keys.publish_comment
            >>= fun publish_comment -> publish_comment' publish_comment msg
          in
          let run =
            let open Irm in
            fetch Keys.check_pull_request_state
            >>= fun () ->
            Abbs_future_combinators.Infix_result_app.(
              (fun () () () () () () () () () () () _ _ -> ())
              <$> fetch Keys.check_access_control_ci_change
              <*> fetch Keys.check_access_control_files
              <*> fetch Keys.check_access_control_repo_config
              <*> fetch Keys.check_valid_destination_branch
              <*> fetch Keys.check_access_control_plan
              <*> fetch Keys.check_account_status_expired
              <*> fetch Keys.check_account_tier
              <*> fetch Keys.check_merge_conflict
              <*> fetch Keys.check_conflicting_plan_work_manifests
              <*> fetch Keys.check_dirspaces_to_plan
              <*> fetch Keys.store_stacks
              (* Ensure that various information is built before trying to run the plan *)
              <*> fetch Keys.branch_dirspaces
              <*> fetch Keys.dest_branch_dirspaces)
          in
          let open Abb.Future.Infix_monad in
          run
          >>= function
          | Ok _ as r -> Abb.Future.return r
          | Error err ->
              let msg =
                match err with
                | #Terrat_base_repo_config_v1.of_version_1_err as err ->
                    Some (Msg.Repo_config_err err)
                | #Terrat_change_match3.synthesize_config_err as err ->
                    Some (Msg.Synthesize_config_err err)
                | `Json_decode_err (fname, err) | `Yaml_decode_err (fname, err) ->
                    Some (Msg.Repo_config_parse_failure (fname, err))
                | `Repo_config_schema_err (fname, err) ->
                    Some (Msg.Repo_config_schema_err (fname, err))
                | `Premium_feature_err feature -> Some (Msg.Premium_feature_err feature)
                | `Config_merge_err details -> Some (Msg.Repo_config_merge_err details)
                | #Terrat_vcs_provider2.fetch_repo_config_with_provenance_err ->
                    Some Msg.Unexpected_temporary_err
                | #Builder.err -> None
              in
              let open Irm in
              CCOption.map_or ~default:(Abb.Future.return (Ok ())) maybe_publish_msg msg
              >>= fun () -> Abb.Future.return (Error err))

    let can_run_apply =
      run ~name:"can_run_apply" (fun s { Bs.Fetcher.fetch } ->
          let maybe_publish_msg msg =
            let open Irm in
            fetch Keys.publish_comment
            >>= fun publish_comment -> publish_comment' publish_comment msg
          in
          let run =
            let open Irm in
            fetch Keys.check_pull_request_state
            >>= fun () ->
            Abbs_future_combinators.Infix_result_app.(
              (fun () () () () () () () () () () () () _ _ _ -> ())
              <$> fetch Keys.check_access_control_ci_change
              <*> fetch Keys.check_access_control_apply
              <*> fetch Keys.check_access_control_files
              <*> fetch Keys.check_access_control_repo_config
              <*> fetch Keys.check_account_status_expired
              <*> fetch Keys.check_account_tier
              <*> fetch Keys.check_conflicting_apply_work_manifests
              <*> fetch Keys.check_dirspaces_missing_plans
              <*> fetch Keys.check_dirspaces_owned_by_other_pull_requests
              <*> fetch Keys.check_dirspaces_to_apply
              <*> fetch Keys.check_gates
              <*> fetch Keys.check_merge_conflict
              <*> fetch Keys.check_apply_requirements
              (* Ensure that various information is built before trying to run the plan *)
              <*> fetch Keys.branch_dirspaces
              <*> fetch Keys.dest_branch_dirspaces)
          in
          let open Abb.Future.Infix_monad in
          run
          >>= function
          | Ok _ as r -> Abb.Future.return r
          | Error err ->
              let msg =
                match err with
                | #Terrat_base_repo_config_v1.of_version_1_err as err ->
                    Some (Msg.Repo_config_err err)
                | #Terrat_change_match3.synthesize_config_err as err ->
                    Some (Msg.Synthesize_config_err err)
                | `Json_decode_err (fname, err) | `Yaml_decode_err (fname, err) ->
                    Some (Msg.Repo_config_parse_failure (fname, err))
                | `Repo_config_schema_err (fname, err) ->
                    Some (Msg.Repo_config_schema_err (fname, err))
                | `Premium_feature_err feature -> Some (Msg.Premium_feature_err feature)
                | `Config_merge_err details -> Some (Msg.Repo_config_merge_err details)
                | #Terrat_vcs_provider2.fetch_repo_config_with_provenance_err ->
                    Some Msg.Unexpected_temporary_err
                | #Builder.err -> None
              in
              let open Irm in
              CCOption.map_or ~default:(Abb.Future.return (Ok ())) maybe_publish_msg msg
              >>= fun () -> Abb.Future.return (Error err))

    let get_context_for_pull_request =
      run ~name:"get_context_for_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request_id
          >>= fun pull_request_id ->
          fetch Keys.store_pull_request
          >>= fun () ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.create_or_get_for_pull_request
                ~request_id:(Builder.log_id s)
                db
                account
                repo
                pull_request_id))

    let eval_pull_request_event =
      run ~name:"eval_pull_request_event" (fun s { Bs.Fetcher.fetch } ->
          let module E = Keys.Pull_request_event in
          let open Irm in
          fetch Keys.context
          >>= fun context ->
          fetch Keys.user
          >>= fun user ->
          fetch Keys.store_pull_request
          >>= fun () ->
          fetch Keys.pull_request_event
          >>= fun pull_request_event ->
          let job_type =
            match pull_request_event with
            | E.Open | E.Sync | E.Ready_for_review -> Some Tjc.Job.Type_.Autoplan
            | E.Close -> Some Tjc.Job.Type_.Autoapply
            | E.Comment { comment_id; comment } -> (
                match comment with
                | Terrat_comment.Apply { tag_query } ->
                    Some (Tjc.Job.Type_.Apply { tag_query; kind = None; force = false })
                | Terrat_comment.Gate_approval { tokens } ->
                    Some (Tjc.Job.Type_.Gate_approval { tokens })
                | Terrat_comment.Plan { tag_query } ->
                    Some (Tjc.Job.Type_.Plan { tag_query; kind = None })
                | Terrat_comment.Apply_force { tag_query } ->
                    Some (Tjc.Job.Type_.Apply { tag_query; kind = None; force = true })
                | Terrat_comment.Repo_config -> Some Tjc.Job.Type_.Repo_config
                | Terrat_comment.Unlock unlocks -> Some (Tjc.Job.Type_.Unlock unlocks)
                | Terrat_comment.Index -> Some Tjc.Job.Type_.Index
                | Terrat_comment.Help
                | Terrat_comment.Apply_autoapprove _
                | Terrat_comment.Feedback _ -> raise (Failure "nyi"))
          in
          match job_type with
          | Some job_type ->
              let comment_id =
                match pull_request_event with
                | E.Comment { comment_id; _ } -> Some comment_id
                | _ -> None
              in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.create ~request_id:(Builder.log_id s) db job_type context user)
              >>= fun job ->
              let log_id = Builder.mk_log_id ~request_id:(Builder.log_id s) job.Tjc.Job.id in
              Logs.info (fun m ->
                  m
                    "%s : target=%s : context_id=%a : log_id= %s : job_type=%a"
                    (Builder.log_id s)
                    (Hmap.Key.info Keys.iter_job)
                    Uuidm.pp
                    context.Tjc.Context.id
                    log_id
                    Tjc.Job.Type_.pp
                    job.Tjc.Job.type_);
              let s' =
                s
                |> Builder.State.orig_store
                |> Keys.Key.add Keys.job job
                |> Keys.Key.add Keys.comment_id comment_id
                |> CCFun.flip Builder.State.set_orig_store s
                |> Builder.State.set_log_id log_id
              in
              Builder.eval s' Keys.react_to_comment >>= fun () -> Abb.Future.return (Ok job)
          | None -> Abb.Future.return (Error `Noop))

    let store_gate_approval =
      run ~name:"store_gate_approval" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.job
          >>= function
          | { Tjc.Job.type_ = Tjc.Job.Type_.Gate_approval { tokens }; _ } -> (
              fetch Keys.user
              >>= function
              | Some user ->
                  Builder.run_db s ~f:(fun db ->
                      Abbs_future_combinators.List_result.iter
                        ~f:(fun token ->
                          S.Gate.add_approval
                            ~request_id:(Builder.log_id s)
                            ~token
                            ~approver:(S.Api.User.to_string user)
                            pull_request
                            db)
                        tokens)
              | None -> assert false)
          | _ -> assert false)
  end

  let tasks tasks =
    let coerce = Builder.coerce_to_task in
    tasks
    |> Hmap.add (coerce Keys.access_control_eval_apply) Tasks.access_control_eval_apply
    |> Hmap.add (coerce Keys.access_control_eval_plan) Tasks.access_control_eval_plan
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.can_run_apply) Tasks.can_run_apply
    |> Hmap.add (coerce Keys.can_run_plan) Tasks.can_run_plan
    |> Hmap.add (coerce Keys.changes) Tasks.changes
    |> Hmap.add (coerce Keys.check_access_control_apply) Tasks.check_access_control_apply
    |> Hmap.add (coerce Keys.check_access_control_ci_change) Tasks.check_access_control_ci_change
    |> Hmap.add (coerce Keys.check_access_control_files) Tasks.check_access_control_files
    |> Hmap.add (coerce Keys.check_access_control_plan) Tasks.check_access_control_plan
    |> Hmap.add
         (coerce Keys.check_access_control_repo_config)
         Tasks.check_access_control_repo_config
    |> Hmap.add (coerce Keys.check_apply_requirements) Tasks.check_apply_requirements
    |> Hmap.add
         (coerce Keys.check_conflicting_apply_work_manifests)
         Tasks.check_conflicting_apply_work_manifests
    |> Hmap.add
         (coerce Keys.check_conflicting_plan_work_manifests)
         Tasks.check_conflicting_plan_work_manifests
    |> Hmap.add (coerce Keys.check_dirspaces_missing_plans) Tasks.check_dirspaces_missing_plans
    |> Hmap.add
         (coerce Keys.check_dirspaces_owned_by_other_pull_requests)
         Tasks.check_dirspaces_owned_by_other_pull_requests
    |> Hmap.add (coerce Keys.check_dirspaces_to_apply) Tasks.check_dirspaces_to_apply
    |> Hmap.add (coerce Keys.check_dirspaces_to_plan) Tasks.check_dirspaces_to_plan
    |> Hmap.add (coerce Keys.check_gates) Tasks.check_gates
    |> Hmap.add (coerce Keys.check_merge_conflict) Tasks.check_merge_conflict
    |> Hmap.add (coerce Keys.check_pull_request_state) Tasks.check_pull_request_state
    |> Hmap.add (coerce Keys.comment_id) Tasks.comment_id
    |> Hmap.add (coerce Keys.create_commit_checks) Tasks.create_commit_checks
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.eval_pull_request_event) Tasks.eval_pull_request_event
    |> Hmap.add (coerce Keys.get_context_for_pull_request) Tasks.get_context_for_pull_request
    |> Hmap.add (coerce Keys.is_draft_pr) Tasks.is_draft_pr
    |> Hmap.add (coerce Keys.missing_autoplan_matches) Tasks.missing_autoplan_matches
    |> Hmap.add (coerce Keys.out_of_change_applies) Tasks.out_of_change_applies
    |> Hmap.add (coerce Keys.publish_comment) Tasks.publish_comment
    |> Hmap.add (coerce Keys.publish_index_complete) Tasks.publish_index_complete
    |> Hmap.add (coerce Keys.publish_repo_config) Tasks.publish_repo_config
    |> Hmap.add (coerce Keys.publish_unlock) Tasks.publish_unlock
    |> Hmap.add (coerce Keys.pull_request) Tasks.pull_request
    |> Hmap.add (coerce Keys.pull_request_diff) Tasks.pull_request_diff
    |> Hmap.add (coerce Keys.pull_request_reviews) Tasks.pull_request_reviews
    |> Hmap.add (coerce Keys.react_to_comment) Tasks.react_to_comment
    |> Hmap.add (coerce Keys.store_gate_approval) Tasks.store_gate_approval
    |> Hmap.add (coerce Keys.store_pull_request) Tasks.store_pull_request
    |> Hmap.add (coerce Keys.store_stacks) Tasks.store_stacks
    |> Hmap.add (coerce Keys.working_branch_name) Tasks.working_branch_name
    |> Hmap.add (coerce Keys.working_branch_ref) Tasks.working_branch_ref
end
