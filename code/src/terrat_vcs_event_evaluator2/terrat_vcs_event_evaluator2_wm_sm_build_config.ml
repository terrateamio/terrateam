module Irm = Abbs_future_combinators.Infix_result_monad
module Msg = Terrat_vcs_provider2.Msg

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Bs = Builder.Bs
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Wm = Terrat_work_manifest3
  module Wmr = Terrat_api_components.Work_manifest_result
  module Bc = Terrat_api_components.Work_manifest_build_config_result
  module Bf = Terrat_api_components.Work_manifest_build_result_failure

  let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
    base_ref = S.Api.Ref.to_string base_ref'
    && branch_ref = S.Api.Ref.to_string branch_ref'
    && steps = [ Wm.Step.Build_config ]

  let create s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    fetch Keys.repo
    >>= fun repo ->
    fetch Keys.dest_branch_ref
    >>= fun dest_branch_ref ->
    fetch Keys.working_branch_ref
    >>= fun working_branch_ref ->
    fetch Keys.initiator
    >>= fun initiator ->
    fetch Keys.target
    >>= fun target ->
    let work_manifest =
      {
        Wm.account;
        base_ref = S.Api.Ref.to_string dest_branch_ref;
        branch_ref = S.Api.Ref.to_string working_branch_ref;
        changes = [];
        completed_at = None;
        created_at = ();
        denied_dirspaces = [];
        environment = None;
        id = ();
        initiator;
        run_id = ();
        runs_on = None;
        state = ();
        steps = [ Wm.Step.Build_config ];
        tag_query = Terrat_tag_query.any;
        target;
      }
    in
    Builder.run_db s ~f:(fun db ->
        S.Work_manifest.create ~request_id:(Builder.log_id s) db work_manifest)
    >>= fun work_manifest ->
    fetch Keys.is_interactive
    >>= function
    | true ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        let module Status = Terrat_commit_check.Status in
        let check =
          S.Commit_check.make_str
            ~config:(Builder.State.config s)
            ~description:"Queued"
            ~status:Status.Queued
            ~work_manifest
            ~repo
            ~account
            "terrateam build-config"
        in
        fetch Keys.client
        >>= fun client ->
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
        >>= fun () -> Abb.Future.return (Ok [ work_manifest ])
    | false -> Abb.Future.return (Ok [ work_manifest ])

  let initiate ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.is_interactive
    >>= (function
    | true ->
        fetch Keys.account
        >>= fun account ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.client
        >>= fun client ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        let module Status = Terrat_commit_check.Status in
        let check =
          S.Commit_check.make_str
            ~config:(Builder.State.config s)
            ~description:"Running"
            ~status:Status.Running
            ~work_manifest
            ~repo
            ~account
            "terrateam build-config"
        in
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
    | false -> Abb.Future.return (Ok ()))
    >>= fun () ->
    fetch Keys.encryption_key
    >>= fun encryption_key ->
    fetch Keys.dest_branch_name
    >>= fun dest_branch_name ->
    fetch Keys.branch_name
    >>= fun branch_name ->
    fetch Keys.repo_tree_branch
    >>= fun repo_tree ->
    fetch Keys.repo_config_raw'
    >>= fun (_, repo_config_raw) ->
    (* FIX: Index *)
    let index = None in
    Abbs_future_combinators.to_result
    @@ Abb.Thread.run (fun () ->
           Terrat_base_repo_config_v1.derive
             ~ctx:
               (Terrat_base_repo_config_v1.Ctx.make
                  ~dest_branch:(S.Api.Ref.to_string dest_branch_name)
                  ~branch:(S.Api.Ref.to_string branch_name)
                  ())
             ~index:
               (CCOption.map_or
                  ~default:Terrat_base_repo_config_v1.Index.empty
                  (fun { Terrat_vcs_provider2.Index.index; _ } -> index)
                  index)
             ~file_list:repo_tree
             repo_config_raw)
    >>= fun repo_config ->
    let module B = Terrat_api_components.Work_manifest_build_config in
    let config =
      repo_config
      |> Terrat_base_repo_config_v1.to_version_1
      |> Terrat_repo_config.Version_1.to_yojson
    in
    let response =
      Terrat_api_components.Work_manifest.Work_manifest_build_config
        {
          B.base_ref = S.Api.Ref.to_string dest_branch_name;
          token = Wm_sm.token encryption_key id;
          type_ = "build-config";
          config;
        }
    in
    Abb.Future.return (Ok response)

  let fail work_manifest s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.is_interactive
    >>= function
    | true ->
        fetch Keys.account
        >>= fun account ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.client
        >>= fun client ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        fetch Keys.user
        >>= fun user ->
        fetch Keys.pull_request
        >>= fun pull_request ->
        let module Status = Terrat_commit_check.Status in
        let check =
          S.Commit_check.make_str
            ~config:(Builder.State.config s)
            ~description:"Failed"
            ~status:Status.Failed
            ~work_manifest
            ~repo
            ~account
            "terrateam build-config"
        in
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
        >>= fun () ->
        S.Comment.publish_comment
          ~request_id:(Builder.log_id s)
          client
          (CCOption.map_or ~default:"" S.Api.User.to_string user)
          pull_request
          Msg.Unexpected_temporary_err
    | false -> Abb.Future.return (Ok ())

  let result work_manifest result s { Bs.Fetcher.fetch } =
    let open Irm in
    let fail msg =
      fetch Keys.is_interactive
      >>= function
      | true ->
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.user
          >>= fun user ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          let module Status = Terrat_commit_check.Status in
          let check =
            S.Commit_check.make_str
              ~config:(Builder.State.config s)
              ~description:"Failed"
              ~status:Status.Failed
              ~work_manifest
              ~repo
              ~account
              "terrateam build-config"
          in
          S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
          >>= fun () ->
          S.Comment.publish_comment
            ~request_id:(Builder.log_id s)
            client
            (CCOption.map_or ~default:"" S.Api.User.to_string user)
            pull_request
            msg
      | false -> Abb.Future.return (Ok ())
    in
    match result with
    | Wmr.Work_manifest_build_config_result { Bc.config } -> (
        let module V1 = Terrat_base_repo_config_v1 in
        let open Abb.Future.Infix_monad in
        Abb.Future.return (V1.of_version_1_json config)
        >>= function
        | Ok _ -> (
            let open Irm in
            fetch Keys.account
            >>= fun account ->
            fetch Keys.working_branch_ref
            >>= fun working_branch_ref ->
            Builder.run_db s ~f:(fun db ->
                S.Db.store_repo_config_json
                  ~request_id:(Builder.log_id s)
                  db
                  account
                  working_branch_ref
                  config)
            >>= fun () ->
            fetch Keys.is_interactive
            >>= function
            | true ->
                fetch Keys.repo
                >>= fun repo ->
                fetch Keys.branch_ref
                >>= fun branch_ref ->
                fetch Keys.client
                >>= fun client ->
                let module Status = Terrat_commit_check.Status in
                let check =
                  S.Commit_check.make_str
                    ~config:(Builder.State.config s)
                    ~description:"Completed"
                    ~status:Status.Completed
                    ~work_manifest
                    ~repo
                    ~account
                    "terrateam build-config"
                in
                S.Api.create_commit_checks
                  ~request_id:(Builder.log_id s)
                  client
                  repo
                  branch_ref
                  [ check ]
            | false -> Abb.Future.return (Ok ()))
        | Error (#Terrat_base_repo_config_v1.of_version_1_err as err) ->
            let open Abbs_future_combinators.Infix_result_monad in
            fail (Msg.Build_config_err err) >>= fun () -> Abb.Future.return (Ok ())
        | Error (`Repo_config_schema_err _ as err) ->
            let open Abbs_future_combinators.Infix_result_monad in
            fail (Msg.Build_config_err err) >>= fun () -> Abb.Future.return (Ok ()))
    | Wmr.Work_manifest_build_result_failure { Bf.msg } -> fail (Msg.Build_config_failure msg)
    | Wmr.Work_manifest_build_tree_result _ -> assert false
    | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result _ -> assert false
    | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result2 _ ->
        assert false
    | Terrat_api_components_work_manifest_result.Work_manifest_index_result _ -> assert false

  let run ~dest_branch_ref ~branch_ref ~name =
    Wm_sm.run ~name ~eq:(eq dest_branch_ref branch_ref) ~create ~initiate ~fail ~result
end
